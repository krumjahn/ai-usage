// Render the real SwiftUI views with synthetic data in a temporary database.
// Run scripts/screenshots.sh from the repository root. Never starts the collector.
import AppKit
import SwiftUI

private struct PreviewFeedback: FeedbackSending {
    var isConfigured: Bool { true }
    func send(_ submission: FeedbackSubmission) async throws { throw FeedbackError.unavailable }
}

@main struct Screenshots {
    @MainActor static func render<V: View>(_ view: V, name: String, dark: Bool = false) throws {
        let host = NSHostingView(rootView: view.environment(\.colorScheme, dark ? .dark : .light))
        host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        host.layoutSubtreeIfNeeded()
        let size = host.bounds.size
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * 2), pixelsHigh: Int(size.height * 2), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = size
        host.cacheDisplay(in: host.bounds, to: rep)
        let url = URL(fileURLWithPath: "docs/images/\(name).png")
        try rep.representation(using: .png, properties: [:])!.write(to: url)
        print("Rendered \(name) \(size)")
    }
    @MainActor static func main() throws {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try ActivityStore(url: directory.appendingPathComponent("demo.sqlite"))
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let desktop = Observation(app: "ChatGPT", bundle: "com.openai.chat")
        let samples: [(Double, Observation)] = [
            (42*60, Observation(app: "Cursor", bundle: "com.todesktop.230313mzl4w4u92")),
            (24*60, desktop),
            (12*60, Observation(app: "Safari", bundle: "com.apple.Safari", domain: "chatgpt.com")),
            (28*60, Observation(app: "Claude", bundle: "com.anthropic.claudefordesktop")),
            (18*60, Observation(app: "Chrome", bundle: "com.google.Chrome", domain: "gemini.google.com")),
            (10*60, Observation(app: "MiniMax Code", bundle: "com.minimax.agent")),
            (66*60, Observation(app: "Notes", bundle: "com.apple.Notes"))
        ]
        var cursor = today.timeIntervalSince1970 + 8*3600
        for (seconds, observation) in samples {
            try store.append([Segment(start: cursor, end: cursor+seconds, observation: observation)])
            cursor += seconds + 60
        }
        for (index, minutes) in [82, 116, 65, 170, 95, 45].enumerated() {
            let day = calendar.date(byAdding: .day, value: -(index+1), to: today)!.timeIntervalSince1970
            try store.append([Segment(start: day+28800, end: day+28800+Double(minutes*60), observation: desktop)])
        }
        let model = LedgerModel(store: store)
        model.refresh(at: today.addingTimeInterval(23*3600))
        let nav = DashboardNavigation()
        try render(MenuBarUI(model: model, collector: model.collector, nav: nav), name: "dashboard")
        try render(MenuBarUI(model: model, collector: model.collector, nav: nav), name: "dashboard-dark", dark: true)
        nav.period = .week
        try render(MenuBarUI(model: model, collector: model.collector, nav: nav), name: "week")
        nav.page = .settings
        try render(MenuBarUI(model: model, collector: model.collector, nav: nav), name: "settings")
        let defaults = UserDefaults(suiteName: "ai-usage-screenshot-\(UUID())")!
        let feedback = FeedbackModel(defaults: defaults, client: PreviewFeedback(), version: "0.1.0")
        try render(FeedbackView(model: feedback).background(Color(nsColor: .windowBackgroundColor)), name: "feedback")
    }
}
