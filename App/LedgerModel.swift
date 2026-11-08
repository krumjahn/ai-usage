import AppKit
import SwiftUI

@MainActor
final class LedgerModel: ObservableObject {
    @Published private(set) var today = UsageAnalytics()
    @Published private(set) var week = [(Date, UsageAnalytics)]()
    @Published var problem: String?

    private var store: ActivityStore?
    let collector = ActivityCollector()
    private var unsaved = [Segment]()
    private var lastReport = Date.distantPast

    init(store: ActivityStore? = nil) {
        self.store = store
    }

    func start() {
        collector.onSample = { [weak self] rows in
            guard let self else { return }
            unsaved += rows
            flush()
            if Date().timeIntervalSince(lastReport) >= 10 { refresh() }
        }
        collector.start()
    }

    private func database() throws -> ActivityStore {
        if let store { return store }
        let opened = try ActivityStore(url: ActivityStore.directory.appendingPathComponent("activity.sqlite"))
        store = opened
        return opened
    }

    func flush() {
        guard !unsaved.isEmpty else { return }
        do {
            try database().append(unsaved)
            unsaved.removeAll()
            problem = nil
        } catch { problem = "Saving delayed. Retrying. " + error.localizedDescription }
    }
    func refresh(at now: Date = Date()) {
        do {
            let cal = Calendar.current
            let midnight = cal.startOfDay(for: now)
            let days = (0..<7).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: midnight) }
            let rows = try database().read(since: days[0].timeIntervalSince1970)
            week = days.map { day in
                let next = cal.date(byAdding: .day, value: 1, to: day)!
                return (day, UsageAnalytics(rows, from: day.timeIntervalSince1970, to: min(next, now).timeIntervalSince1970))
            }
            today = week.last!.1
            lastReport = now
        } catch { problem = error.localizedDescription }
    }
    func deleteHistory() {
        do {
            try database().erase()
            unsaved.removeAll()
            collector.resetSampling()
            problem = nil
            refresh()
        } catch { problem = error.localizedDescription }
    }
    func export() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "ai-usage.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        struct Record: Encodable {
            let segment: Segment
            let classification: AIToolClassifier.Match
            let state: String
        }
        do {
            let records = try database().read().map {
                Record(segment: $0, classification: AIToolClassifier.classify($0.observation),
                       state: $0.observation == .idle ? "idle" : "foreground")
            }
            try JSONEncoder().encode(records).write(to: url, options: .atomic)
        } catch { problem = error.localizedDescription }
    }
}
