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

private let panelWidth: CGFloat = 320

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
    private var weekSplits: [String: AttentionSplit] {
        model.week.reduce(into: [:]) { $0.merge($1.1.toolSplits, uniquingKeysWith: +) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if let problem = model.problem { Text(problem).foregroundStyle(.red).font(.caption) }
            switch nav.page {
            case .dashboard: dashboard
            case .tools: tools
            case .settings: PrivacySettings(model: model, collector: collector)
            }
        }
        .padding(16).frame(width: panelWidth).fixedSize(horizontal: false, vertical: true)
        .background(Color(nsColor: .windowBackgroundColor))
        .tint(.primary)
    }

    private var header: some View {
        HStack(spacing: 6) {
            if nav.page == .dashboard {
                Text("AI Usage").font(.system(size: 13, weight: .semibold))
                Spacer()
                Button { nav.page = .settings } label: {
                    Image(systemName: "gearshape").frame(width: 22, height: 22)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                .accessibilityLabel("Settings").help("Settings")
            } else {
                Button { nav.openDashboard() } label: {
                    Image(systemName: "chevron.left").frame(width: 22, height: 22)
                }
                .buttonStyle(.plain).accessibilityLabel("Back to dashboard")
                Text(nav.page == .tools ? "All tools" : "Settings")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
        }
    }

    @ViewBuilder private var dashboard: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("AI attention today")
                Spacer()
                Text(tracking).lineLimit(1)
            }.font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline) {
                Text(duration(model.today.ai))
                    .font(.system(size: 36, weight: .medium)).tracking(-1.5).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.7)
                Spacer()
                if model.today.active > 0 {
                    let share = (model.today.ai / model.today.active).formatted(.percent.precision(.fractionLength(0)))
                    Text("\(share) active").font(.caption).foregroundStyle(.secondary)
                        .fixedSize().help("\(share) of all active foreground time")
                        .accessibilityLabel("\(share) of all active foreground time")
                }
            }
            AttentionSplitSummary(split: model.today.split)
        }
        Divider()
        toolRows(model.today.toolSplits, limit: 3)
        Button { nav.page = .tools } label: {
            HStack {
                Text("All tools")
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold))
            }.contentShape(Rectangle())
        }
        .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
        .accessibilityLabel("All AI Tools")
        Divider()
        AttentionWeek(days: model.week)
        if !collector.sites {
            Button { nav.page = .settings } label: {
                HStack(spacing: 5) {
                    Image(systemName: "globe")
                    Text("Include AI websites")
                    Spacer()
                    Image(systemName: "plus").font(.system(size: 10))
                }.contentShape(Rectangle())
            }
            .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
            .help("Enable browser identification in Settings")
        }
    }

    @ViewBuilder private var tools: some View {
        Picker("Period", selection: $nav.period) {
            ForEach(ToolPeriod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }.pickerStyle(.segmented).labelsHidden()
        let splits = nav.period == .today ? model.today.toolSplits : weekSplits
        let combined = splits.values.reduce(AttentionSplit(), +)
        VStack(alignment: .leading, spacing: 3) {
            Text("\(duration(combined.total)) AI attention").font(.headline)
            AttentionSplitSummary(split: combined)
        }
        if splits.count > 6 {
            ScrollView { toolRows(splits) }.frame(height: 228)
        } else {
            toolRows(splits)
        }
        Divider()
        Text("Hover over a tool for its web and desktop split. Foreground time only.")
            .font(.caption).foregroundStyle(.secondary)
    }

    @ViewBuilder private func toolRows(_ splits: [String: AttentionSplit], limit: Int = .max) -> some View {
        let totals = splits.mapValues(\.total)
        let sorted = totals.sorted { (a: (key: String, value: Double), b: (key: String, value: Double)) in
            a.value == b.value ? a.key < b.key : a.value > b.value
        }
        if sorted.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your first minutes start here.").font(.callout.weight(.medium))
                Text("Use an AI app, or enable websites in Settings. Time appears as you work.")
                    .font(.caption).foregroundStyle(.secondary)
            }.fixedSize(horizontal: false, vertical: true)
        } else {
            VStack(spacing: 8) {
                ForEach(Array(sorted.prefix(limit)), id: \.key) { name, seconds in
                    HStack(spacing: 8) {
                        ToolIcon(name: name)
                        Text(name).font(.callout).lineLimit(1).truncationMode(.tail)
                        Spacer(minLength: 8)
                        Text(duration(seconds)).font(.callout).monospacedDigit()
                            .foregroundStyle(.secondary).fixedSize()
                    }
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .ignore)
                    .help(AttentionSplitSummary.description(splits[name] ?? AttentionSplit()))
                    .accessibilityLabel("\(name), \(duration(seconds)). \(AttentionSplitSummary.description(splits[name] ?? AttentionSplit()))")
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
                Image(systemName: Self.symbols[name] ?? "app").font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 5))
            }
        }.frame(width: 22, height: 22).accessibilityHidden(true)
    }
}

private struct AttentionWeek: View {
    let days: [(Date, UsageAnalytics)]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Past 7 days")
                Spacer()
                Text(duration(days.reduce(0) { $0 + $1.1.ai })).monospacedDigit()
            }.font(.caption).foregroundStyle(.secondary)
            let peak = days.map { $0.1.ai }.max() ?? 0
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(days.indices, id: \.self) { i in
                    let (date, stats) = days[i]
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(stats.ai > 0 ? Color.primary.opacity(0.7) : Color.secondary.opacity(0.2))
                            .frame(width: 8, height: stats.ai > 0 ? max(3, 22 * stats.ai / max(1, peak)) : 2)
                            .frame(height: 22, alignment: .bottom)
                        Text(date, format: .dateTime.weekday(.abbreviated))
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity)
                    .help("\(date.formatted(date: .abbreviated, time: .omitted)): \(duration(stats.ai))")
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)), \(duration(stats.ai)) AI attention")
                }
            }
        }
    }
}

struct PrivacySettings: View {
    @ObservedObject var model: LedgerModel
    @ObservedObject var collector: ActivityCollector
    @State private var confirming = false
    private var browserAccess: String {
        guard collector.sites else { return "Off" }
        return collector.browserStatus == "Off" ? "Waiting for a supported browser" : collector.browserStatus
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recording").font(.callout.weight(.medium))
                Spacer()
                Button(collector.paused ? "Resume" : "Pause") { collector.togglePause() }
            }
            Divider()
            Toggle("Identify AI websites", isOn: Binding(get: { collector.sites }, set: { _ in collector.toggleSites() }))
                .toggleStyle(.switch)
            Text("Browser access · " + browserAccess).font(.caption.weight(.medium))
            Text("Identify AI sites in Safari, Chrome, Arc, Edge or Brave. Allow Automation access when macOS asks.")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            Text("On this Mac").font(.callout.weight(.medium))
            Text("App names, recognized AI domains and time intervals stay on this Mac. No prompts or page contents.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Export JSON…") { model.export() }
                Button("Delete history…", role: .destructive) { confirming = true }
            }
            Divider()
            Button("Quit AI Usage") { NSApplication.shared.terminate(nil) }.buttonStyle(.link)
        }.controlSize(.small).fixedSize(horizontal: false, vertical: true)
        .alert("Delete AI Usage history?", isPresented: $confirming) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { model.deleteHistory() }
        } message: { Text("This permanently clears the activity recorded on this Mac.") }
    }
}
