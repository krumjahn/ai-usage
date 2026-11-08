import SwiftUI

enum DashboardPage { case dashboard, tools, settings }
enum ToolPeriod: String, CaseIterable { case today = "Today", week = "Last 7 days" }

@MainActor final class DashboardNavigation: ObservableObject {
    @Published var page = DashboardPage.dashboard
    @Published var period = ToolPeriod.today
    func openDashboard() {
        page = .dashboard
        period = .today
    }
}

private let ledgerTeal = Color(red: 0.12, green: 0.52, blue: 0.52)

struct MenuBarUI: View {
    @ObservedObject var model: LedgerModel
    @ObservedObject var collector: ActivityCollector
    @ObservedObject var nav: DashboardNavigation

    private var tracking: String {
        if collector.paused { return "Paused" }
        if ["Idle", "Session inactive", "Starting", "Waiting for foreground app"].contains(collector.status) {
            return collector.status
        }
        return "Tracking"
    }
    private var weekTools: [String: Double] {
        model.week.reduce(into: [:]) { $0.merge($1.1.tools, uniquingKeysWith: +) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            header
            if let problem = model.problem { Text(problem).foregroundStyle(.red).font(.caption) }
            switch nav.page {
            case .dashboard: dashboard
            case .tools: tools
            case .settings: PrivacySettings(model: model, collector: collector)
            }
        }
        .padding(18).frame(width: 420).fixedSize(horizontal: false, vertical: true)
        .background(Color(nsColor: .windowBackgroundColor))
        .tint(ledgerTeal)
    }

    private var header: some View {
        HStack(spacing: 9) {
            if nav.page == .dashboard {
                Image(systemName: "chart.bar.fill").foregroundStyle(.white)
                    .frame(width: 31, height: 31).background(ledgerTeal.gradient, in: RoundedRectangle(cornerRadius: 8))
                Text("AI Usage").font(.system(size: 19, weight: .semibold))
                Spacer()
                HStack(spacing: 5) {
                    Circle().fill(tracking == "Tracking" ? Color.green : Color.secondary).frame(width: 6, height: 6)
                    Text(tracking).font(.caption.weight(.medium))
                }.padding(.horizontal, 8).padding(.vertical, 4).background(.primary.opacity(0.055), in: Capsule())
                Button { nav.page = .settings } label: { Image(systemName: "gearshape").frame(width: 25, height: 25) }
                    .buttonStyle(.plain).accessibilityLabel("Settings").help("Settings")
            } else {
                Button { nav.openDashboard() } label: { Image(systemName: "chevron.left").frame(width: 23, height: 25) }
                    .buttonStyle(.plain).accessibilityLabel("Back to dashboard")
                Text(nav.page == .tools ? "All AI Tools" : "Settings")
                    .font(.title3.weight(.semibold))
                Spacer()
            }
        }
    }

    @ViewBuilder private var dashboard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI attention today").font(.subheadline.weight(.medium))
                Text(duration(model.today.ai)).font(.system(size: 36, weight: .semibold, design: .rounded)).monospacedDigit()
                Text("Active foreground use").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(model.today.active > 0 ? (model.today.ai / model.today.active).formatted(.percent.precision(.fractionLength(0))) : "—")
                    .font(.title2.weight(.semibold)).monospacedDigit()
                Text("of active time").font(.caption).foregroundStyle(.secondary)
            }
        }.padding(14).background(ledgerTeal.opacity(0.085), in: RoundedRectangle(cornerRadius: 12))
        HStack {
            Text("Your AI tools").font(.headline)
            Spacer()
            Button("All AI Tools ›") { nav.page = .tools }.buttonStyle(.link)
        }
        toolRows(model.today.tools, limit: 3)
        Divider()
        AttentionWeek(days: model.week)
        Divider()
        HStack(spacing: 8) {
            Image(systemName: "globe").foregroundStyle(ledgerTeal)
            Text("AI website identification").font(.callout)
            Spacer()
            if collector.sites {
                Button("Manage") { nav.page = .settings }.buttonStyle(.link)
            } else {
                Button("Enable…") { nav.page = .settings }.controlSize(.small)
            }
        }
    }

    @ViewBuilder private var tools: some View {
        Picker("Period", selection: $nav.period) {
            ForEach(ToolPeriod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }.pickerStyle(.segmented).labelsHidden()
        let totals = nav.period == .today ? model.today.tools : weekTools
        Text("\(duration(totals.values.reduce(0, +))) AI attention").font(.headline)
        if totals.count > 7 {
            ScrollView { toolRows(totals) }.frame(height: 300)
        } else {
            toolRows(totals)
        }
        Divider()
        Text("Claude Code and other terminal agents need direct product evidence to receive their own time.")
            .font(.caption).foregroundStyle(.secondary)
    }

    @ViewBuilder private func toolRows(_ totals: [String: Double], limit: Int = .max) -> some View {
        let sorted = totals.sorted { (a: (key: String, value: Double), b: (key: String, value: Double)) in
            a.value == b.value ? a.key < b.key : a.value > b.value
        }
        if sorted.isEmpty {
            Label("Use an AI app, or enable AI website identification in Settings. Recorded attention will appear here.", systemImage: "sparkle.magnifyingglass")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        } else {
            VStack(spacing: 10) {
                ForEach(Array(sorted.prefix(limit)), id: \.key) { name, seconds in
                    HStack(spacing: 10) {
                        ToolIcon(name: name)
                        VStack(spacing: 5) {
                            HStack {
                                Text(name).font(.callout.weight(.medium))
                                Spacer()
                                Text(duration(seconds)).font(.callout).monospacedDigit()
                            }
                            GeometryReader { geo in
                                Capsule().fill(.primary.opacity(0.06))
                                    .overlay(alignment: .leading) {
                                        Capsule().fill(ledgerTeal).frame(width: geo.size.width * seconds / (sorted.first?.value ?? seconds))
                                    }
                            }.frame(height: 4)
                        }
                    }
                }
                if totals["Unknown"] != nil {
                    Text("Unknown includes AI app time where the product could not be identified.")
                        .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

private struct ToolIcon: View {
    let name: String
    private static let native: [String: NSImage] = {
        var icons = [String: NSImage]()
        let ids = Set(AIToolClassifier.bundles.keys).union(AIToolClassifier.desktopIdentities.map(\.bundle))
        for id in ids.sorted() {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id),
                  let bundle = Bundle(url: url) else { continue }
            let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? id
            if let tool = AIToolClassifier.classify(Observation(app: name, bundle: id)).tool {
                icons[tool] = NSWorkspace.shared.icon(forFile: url.path)
            }
        }
        return icons
    }()
    private static let symbols = ["Unknown": "questionmark", "Claude": "sun.max", "Claude Code": "terminal",
        "Codex": "chevron.left.forwardslash.chevron.right", "ChatGPT": "bubble.left.and.bubble.right", "Gemini": "sparkles",
        "Cursor": "cursorarrow", "Grok": "bolt", "Grok Bot": "bolt", "Windsurf": "wind", "Perplexity": "magnifyingglass"]
    var body: some View {
        Group {
            if let image = Self.native[name] { Image(nsImage: image).resizable().scaledToFit().padding(2) }
            else {
                Image(systemName: Self.symbols[name] ?? "app").font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
            }
        }.frame(width: 30, height: 30).accessibilityHidden(true)
    }
}

private struct AttentionWeek: View {
    let days: [(Date, UsageAnalytics)]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("AI activity").font(.headline)
                Spacer()
                Text("Last 7 days").foregroundStyle(.secondary).font(.caption)
            }
            let peak = days.map { $0.1.ai }.max() ?? 0
            HStack(alignment: .bottom, spacing: 7) {
                ForEach(days.indices, id: \.self) { i in
                    let (date, stats) = days[i]
                    VStack(spacing: 4) {
                        Text(stats.ai > 0 ? duration(stats.ai) : "").font(.system(size: 10)).lineLimit(1).minimumScaleFactor(0.75)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(stats.ai > 0 ? ledgerTeal : Color.secondary.opacity(0.2))
                            .frame(height: stats.ai > 0 ? max(3, 36 * stats.ai / max(1, peak)) : 1)
                        Text(date, format: .dateTime.weekday(.abbreviated)).font(.caption2).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)), \(duration(stats.ai)) AI attention")
                }
            }.frame(height: peak > 0 ? 70 : 24, alignment: .bottom)
        }
    }
}

struct PrivacySettings: View {
    @ObservedObject var model: LedgerModel
    @ObservedObject var collector: ActivityCollector
    @State private var confirming = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Activity collection", systemImage: "waveform.path.ecg").font(.headline)
                Spacer()
                Button(collector.paused ? "Resume" : "Pause") { collector.togglePause() }
            }
            Divider()
            Toggle("Identify AI websites", isOn: Binding(get: { collector.sites }, set: { _ in collector.toggleSites() }))
                .toggleStyle(.switch)
            Text("Browser access · " + collector.browserStatus).font(.caption.weight(.medium))
            Text("Enable identification, then visit an AI site in Safari, Chrome, Arc, Edge or Brave. Choose Allow when macOS asks for Automation access.")
                .font(.callout).foregroundStyle(.secondary)
            Divider()
            Label("Local history", systemImage: "lock").font(.headline)
            Text("This Mac stores app names, bundle IDs, recognized AI domains and time intervals.")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button("Export JSON…") { model.export() }
                Button("Delete history…", role: .destructive) { confirming = true }
            }
            Divider()
            Button("Quit AI Usage") { NSApplication.shared.terminate(nil) }.buttonStyle(.link)
        }.fixedSize(horizontal: false, vertical: true)
        .alert("Delete AI Usage history?", isPresented: $confirming) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { model.deleteHistory() }
        } message: { Text("This permanently clears the activity recorded on this Mac.") }
    }
}
