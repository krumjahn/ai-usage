import XCTest
@testable import AttentionLedger

final class AttentionSplitTests: XCTestCase {
    func testEmptyAndSingleSourceReportsReconcileWithCombinedTime() {
        let empty = UsageAnalytics()
        XCTAssertEqual(empty.split, AttentionSplit())
        XCTAssertEqual(empty.ai, 0)
        XCTAssertEqual(AttentionSplitSummary.description(empty.split), "Web 0s · Desktop 0s")

        for (observation, expected) in [
            (Observation(app: "Safari", bundle: "com.apple.Safari", domain: "claude.ai"), AttentionSplit(web: 60)),
            (Observation(app: "Claude", bundle: "com.anthropic.claudefordesktop"), AttentionSplit(desktop: 60))
        ] {
            let report = UsageAnalytics([Segment(start: 0, end: 60, observation: observation)], from: 0, to: 60)
            XCTAssertEqual(report.split, expected)
            XCTAssertEqual(report.ai, report.split.web + report.split.desktop)
            XCTAssertEqual(report.tools["Claude"], expected.total)
        }
    }

    @MainActor func testDailyAndWeeklySplitsRespectMidnightAndPreserveRows() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try ActivityStore(url: directory.appendingPathComponent("test.sqlite"))
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())
        let start = midnight.timeIntervalSince1970
        let rows = [
            Segment(start: start - 60, end: start + 60,
                    observation: Observation(app: "Chrome", bundle: "com.google.Chrome", domain: "chatgpt.com")),
            Segment(start: start + 60, end: start + 180,
                    observation: Observation(app: "ChatGPT", bundle: "com.openai.chat"))
        ]
        try store.append(rows)
        let saved = try store.read()
        let model = LedgerModel(store: store)
        model.refresh(at: midnight.addingTimeInterval(180))
        XCTAssertEqual(model.today.split, AttentionSplit(web: 60, desktop: 120))
        XCTAssertEqual(model.today.ai, 180)
        let weekly = model.week.reduce(into: [String: AttentionSplit]()) {
            $0.merge($1.1.toolSplits, uniquingKeysWith: +)
        }
        XCTAssertEqual(weekly["ChatGPT"], AttentionSplit(web: 120, desktop: 120))
        XCTAssertEqual(weekly.values.reduce(AttentionSplit(), +).total, 240)
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: midnight))
        model.refresh(at: tomorrow)
        XCTAssertEqual(model.today.split, AttentionSplit())
        XCTAssertEqual(try store.read(), saved)
    }
}
