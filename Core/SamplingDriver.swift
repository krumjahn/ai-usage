import AppKit
import Combine

@MainActor final class ActivityCollector: ObservableObject {
    @Published private(set) var status = "Starting"
    @Published private(set) var browserStatus = "Off"
    @Published private(set) var paused = UserDefaults.standard.bool(forKey: "paused")
    @Published private(set) var sites = UserDefaults.standard.bool(forKey: "sites")
    private var pipeline = SegmentCoalescer()
    private var timer: Timer?
    private var asleep = false
    private var browserPID: pid_t?
    private var host: String?
    private var hostValidUntil = Date.distantPast
    private var requestGeneration = 0
    private var fetching = false
    private var retryAfter = [String: Date]()
    var onSample: ([Segment]) -> Void = { _ in }

    func start() {
        guard timer == nil else { return }
        for (name, sleeping) in [(NSWorkspace.willSleepNotification, true), (NSWorkspace.didWakeNotification, false),
                                  (NSWorkspace.sessionDidResignActiveNotification, true), (NSWorkspace.sessionDidBecomeActiveNotification, false)] {
            NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.asleep = sleeping
                    self?.resetSampling()
                    self?.tick()
                }
            }
        }
        tick()
        let clock = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(clock, forMode: .common)
        timer = clock
    }

    private func tick() {
        let now = Date()
        var committed = [Segment]()
        if paused || asleep {
            status = paused ? "Paused" : "Session inactive"
        } else {
            let running = SystemSampler.foreground()
            let id = running?.bundleIdentifier ?? ""
            let idle = SystemSampler.idleSeconds()
            let locked = id == "com.apple.loginwindow"
            let active = idle < pipeline.idleThreshold && !locked
            let pid = active && sites && BrowserAdapter.supported.contains(id) ? running?.processIdentifier : nil
            if pid != browserPID {
                invalidateBrowser()
                browserPID = pid
            }
            if let pid { probe(id: id, pid: pid, now: now) }
            if now >= hostValidUntil { host = nil }
            let app = running.map { Observation(app: $0.localizedName ?? id, bundle: id, domain: host) }
            status = active ? (host ?? app?.app ?? "Waiting for foreground app") : "Idle"
            committed = pipeline.sample(at: now.timeIntervalSince1970, idle: idle,
                                       app: locked ? .idle : app)
        }
        onSample(committed)
    }

    private func invalidateBrowser() {
        requestGeneration += 1
        browserPID = nil
        host = nil
        browserStatus = sites ? "Waiting for a supported browser" : "Off"
    }
    func resetSampling() {
        pipeline.reset()
        invalidateBrowser()
    }
    private func probe(id: String, pid: pid_t, now: Date) {
        if let retry = retryAfter[id], retry > now {
            browserStatus = "Automation denied · " + id
            return
        }
        guard !fetching else { return }
        fetching = true
        let generation = requestGeneration
        Task {
            let result = await Task.detached(priority: .utility) { BrowserAdapter.fetch(id) }.value
            fetching = false
            guard generation == requestGeneration, SystemSampler.foreground()?.processIdentifier == pid else { return }
            switch result {
            case .allowed(let domain):
                host = domain
                hostValidUntil = Date().addingTimeInterval(4)
                browserStatus = "Allowed · " + id
            case .denied:
                host = nil
                retryAfter[id] = Date().addingTimeInterval(600)
                browserStatus = "Automation denied · " + id
            case .unavailable:
                host = nil
                browserStatus = "Tab unavailable · " + id
            }
        }
    }
    func togglePause() {
        paused.toggle()
        UserDefaults.standard.set(paused, forKey: "paused")
        resetSampling()
        tick()
    }
    func toggleSites() {
        sites.toggle()
        UserDefaults.standard.set(sites, forKey: "sites")
        retryAfter.removeAll()
        resetSampling()
        tick()
    }
}
