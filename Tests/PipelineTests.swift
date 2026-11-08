import XCTest
import SQLite3
import SwiftUI
@testable import AttentionLedger

final class PipelineTests: XCTestCase {
    let codex = Observation(app: "Codex", bundle: "com.openai.codex")
    func testPrivateDomainsAndUnknownTools() {
        XCTAssertEqual(AIToolClassifier.domain(from: "https://secret.claude.ai/chat/private?q=a"), "claude.ai")
        for url in ["https://claude.ai.example.net", "https://private.example.com", "file://claude.ai/test"] {
            XCTAssertNil(AIToolClassifier.domain(from: url))
        }
        XCTAssertNil(AIToolClassifier.classify(Observation(app: "Claude", bundle: "com.apple.Terminal")).tool)
        XCTAssertEqual(AIToolClassifier.classify(codex).evidence, "bundle:com.openai.codex")
    }
    func testIdleFromLastInputAndWakeGap() {
        var c = SegmentCoalescer()
        var rows = c.sample(at: 1000, idle: 0, app: codex)
        rows += c.sample(at: 1005, idle: 2, app: codex)
        for time in stride(from: 1010, through: 1130, by: 5) {
            rows += c.sample(at: Double(time), idle: Double(time-1003), app: codex)
        }
        XCTAssertEqual(UsageAnalytics(rows, from: 1000, to: 1130).ai, 3)
        XCTAssertEqual(rows.last?.observation, .idle)
        XCTAssertTrue(c.sample(at: 2000, idle: 0, app: codex).isEmpty)
    }
    func testUnionAndDayBoundary() {
        let rows = [Segment(start: 0, end: 20, observation: codex), Segment(start: 15, end: 30, observation: codex)]
        XCTAssertEqual(UsageAnalytics(rows, from: 5, to: 25).active, 20)
    }
    func testWebAndDesktopCombineByToolWithoutDoubleCounting() {
        let products = [("ChatGPT", "com.openai.chat", "chatgpt.com"),
                        ("ChatGPT", "com.openai.codex", "chat.openai.com"),
                        ("Claude", "com.anthropic.claudefordesktop", "claude.ai"),
                        ("MiniMax Code", "com.minimax.agent", "agent.minimax.io")]
        for (name, bundle, domain) in products {
            let rows = [
                Segment(start: 0, end: 60, observation: Observation(app: name, bundle: bundle)),
                Segment(start: 30, end: 90, observation: Observation(app: "Chrome", bundle: "com.google.Chrome", domain: domain)),
                Segment(start: 90, end: 120, observation: Observation(app: "Chrome", bundle: "com.google.Chrome")),
                Segment(start: 120, end: 180, observation: .idle),
                Segment(start: 180, end: 210, observation: codex)
            ]
            let report = UsageAnalytics(rows, from: 0, to: 210)
            XCTAssertEqual(report.tools, [name: 90, "Codex": 30])
            XCTAssertEqual(report.toolSplits[name], AttentionSplit(web: 30, desktop: 60))
            XCTAssertEqual(report.toolSplits["Codex"], AttentionSplit(web: 0, desktop: 30))
            XCTAssertEqual(report.split, AttentionSplit(web: 30, desktop: 90))
            XCTAssertEqual(report.ai, 120, "Web/desktop overlap must count once")
            XCTAssertEqual(report.active, 150, "Ordinary browsing is active but not AI")
        }
    }
    func testPersistenceRollbackAndErase() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("test.sqlite")
        var store: ActivityStore? = try ActivityStore(url: url)
        let a = Segment(start: 1, end: 2, observation: codex)
        try store?.append([a, Segment(start: 2, end: 4, observation: codex)])
        XCTAssertThrowsError(try store?.append([Segment(start: 5, end: 6, observation: codex), a]))
        store = nil
        store = try ActivityStore(url: url)
        XCTAssertEqual(try store?.read(), [Segment(start: 1, end: 4, observation: codex, recordedClassification: AIToolClassifier.classify(codex))])
        try store?.erase()
        XCTAssertEqual(try store?.read(), [])
    }
}

extension PipelineTests {
    func testDesktopNamesDisambiguateSharedBundleIDs() {
        let observation = Observation(app: "ChatGPT", bundle: "com.openai.codex")
        XCTAssertEqual(AIToolClassifier.classify(observation).tool, "ChatGPT")
        XCTAssertEqual(AIToolClassifier.classify(codex).tool, "Codex")
        let grok = Observation(app: "Grok Bot", bundle: "com.anysphere.sand")
        XCTAssertEqual(AIToolClassifier.classify(grok).tool, "Grok Bot")
        XCTAssertEqual(AIToolClassifier.classify(grok).evidence, "bundle:com.anysphere.sand;app:Grok Bot")
        XCTAssertNil(AIToolClassifier.classify(Observation(app: "Other App", bundle: grok.bundle)).tool)
        XCTAssertNil(AIToolClassifier.classify(Observation(app: "Grok Bot", bundle: "com.apple.Terminal")).tool)
    }

    func testRegistryCoverage() {
        let hosts = ["chatgpt.com": "ChatGPT", "claude.ai": "Claude", "gemini.google.com": "Gemini", "grok.com": "Grok"]
        for (host, name) in hosts {
            let match = AIToolClassifier.classify(Observation(app: "Safari", bundle: "com.apple.Safari", domain: host))
            XCTAssertEqual(match.tool, name)
            XCTAssertEqual(match.version, 6)
            XCTAssertEqual(match.evidence, "domain:" + host)
        }
        for (id, name) in [("com.openai.codex","Codex"), ("com.todesktop.230313mzl4w4u92","Cursor"),
                           ("com.exafunction.windsurf","Windsurf")] {
            XCTAssertEqual(AIToolClassifier.classify(Observation(app: "App", bundle: id)).tool, name)
        }
    }

    func testResetDropsUnobservedTimeAndRestartsAtNewApp() {
        var c = SegmentCoalescer()
        _ = c.sample(at: 10, idle: 0, app: codex)
        _ = c.sample(at: 12, idle: 2, app: codex)
        c.reset()
        let terminal = Observation(app: "Terminal", bundle: "com.apple.Terminal")
        XCTAssertTrue(c.sample(at: 5000, idle: 0, app: terminal).isEmpty)
        let rows = c.sample(at: 5002, idle: 0, app: terminal)
        XCTAssertEqual(rows, [Segment(start: 5000, end: 5002, observation: terminal)])
        XCTAssertEqual(UsageAnalytics(rows, from: 0, to: 6000).ai, 0)
    }
}

extension PipelineTests {
    func testLegacyMigrationPreservesObservations() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("test.sqlite")
        var db: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &db), SQLITE_OK)
        XCTAssertEqual(sqlite3_exec(db, """
            CREATE TABLE segments(start REAL PRIMARY KEY,end REAL,app TEXT,bundle TEXT,domain TEXT);
            INSERT INTO segments VALUES(2,8,'Safari','com.apple.Safari','claude.ai');
            PRAGMA user_version=1;
            """, nil, nil, nil), SQLITE_OK)
        sqlite3_close(db)
        let store = try ActivityStore(url: url)
        let row = try XCTUnwrap(store.read().first)
        XCTAssertNil(row.recordedClassification)
        XCTAssertEqual(AIToolClassifier.classify(row.observation).tool, "Claude")
        XCTAssertEqual(row.end - row.start, 6)
    }
}

extension PipelineTests {
    func testAIAttributionNeedsProductEvidence() {
        for browser in ["com.google.Chrome", "com.apple.Safari"] {
            XCTAssertNil(AIToolClassifier.classify(Observation(app: "Browser", bundle: browser)).tool)
            XCTAssertEqual(AIToolClassifier.classify(Observation(app: "Browser", bundle: browser, domain: "claude.ai")).tool, "Claude")
        }
        XCTAssertTrue(AIToolClassifier.products.contains("Claude Code"))
        XCTAssertNil(AIToolClassifier.classify(Observation(app: "Claude Code", bundle: "com.apple.Terminal")).tool)
        XCTAssertEqual(AIToolClassifier.classify(Observation(app: "ChatGPT Classic", bundle: "com.openai.chat")).tool, "ChatGPT")
        XCTAssertEqual(AIToolClassifier.classify(codex).tool, "Codex")
    }
    func testExistingDesktopObservationsAreReclassifiedForAnalytics() {
        let original = AIToolClassifier.Match(tool: "Unknown", evidence: "legacy", version: 3)
        let rows = [
            Segment(start: 0, end: 30, observation: Observation(app: "ChatGPT", bundle: "com.openai.codex"),
                    recordedClassification: original),
            Segment(start: 30, end: 45, observation: Observation(app: "Grok Bot", bundle: "com.anysphere.sand"))
        ]
        let report = UsageAnalytics(rows, from: 0, to: 60)
        XCTAssertEqual(report.tools, ["ChatGPT": 30, "Grok Bot": 15])
        XCTAssertEqual(report.ai, report.active)
        XCTAssertEqual(rows.first?.recordedClassification, original)
    }
    @MainActor func testDashboardIsDefaultOnEveryPresentation() {
        let nav = DashboardNavigation()
        XCTAssertEqual(nav.page, .dashboard)
        nav.page = .settings
        nav.period = .week
        nav.openDashboard()
        XCTAssertEqual(nav.page, .dashboard)
        XCTAssertEqual(nav.period, .today)
        nav.page = .settings
        nav.openDashboard()
        XCTAssertEqual(nav.page, .dashboard)
    }

    @MainActor func testDashboardFitsEmptySparseAndMultiweekHistory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try ActivityStore(url: directory.appendingPathComponent("test.sqlite"))
        let model = LedgerModel(store: store)
        let nav = DashboardNavigation()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())
        let noon = midnight.addingTimeInterval(12 * 3600)
        let domains = AIToolClassifier.domains.keys.sorted()

        for span in [0, 1, 21] {
            let daysToInsert = span == 21 ? 1..<21 : 0..<span
            for offset in daysToInsert {
                let date = try XCTUnwrap(calendar.date(byAdding: .day, value: -offset, to: midnight))
                let rows = domains.enumerated().map { i, host in
                    let start = date.timeIntervalSince1970 + 3600 + Double(i * 120)
                    return Segment(start: start, end: start + 60, observation:
                        Observation(app: "Safari", bundle: "com.apple.Safari", domain: host))
                }
                try store.append(rows)
            }
            model.refresh(at: noon)
            XCTAssertNil(model.problem)
            XCTAssertEqual(model.week.count, 7)
            XCTAssertEqual(model.week.filter { $0.1.ai > 0 }.count, min(span, 7))
            XCTAssertEqual(model.today.ai, span == 0 ? 0 : Double(domains.count * 60))
            for scheme in [ColorScheme.light, .dark] {
                for period in ToolPeriod.allCases {
                    nav.period = period
                    for page in [DashboardPage.dashboard, .settings] {
                        nav.page = page
                        let view = NSHostingView(rootView: MenuBarUI(model: model, collector: model.collector, nav: nav)
                            .environment(\.colorScheme, scheme))
                        let size = view.fittingSize
                        XCTAssertEqual(size.width, 320, accuracy: 1)
                        XCTAssertTrue((120...500).contains(size.height), "\(page) height \(size.height)")
                        if page == .dashboard { XCTAssertLessThanOrEqual(size.height, 460) }
                    }
                }
            }
        }
    }
}
