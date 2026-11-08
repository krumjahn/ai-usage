import Combine
import XCTest
@testable import AttentionLedger

final class MenuBarTimeTests: XCTestCase {
    func testCompactTimeAcrossMinuteAndHourBoundaries() {
        for (seconds, expected) in [(0.0, "0s"), (59.9, "59s"), (60, "1m"),
                                    (3599, "59m"), (3600, "1h 0m"), (7380, "2h 3m")] {
            let value = AttentionMenuBarPresentation(seconds: seconds, paused: false, status: "Tracking", problem: nil)
            XCTAssertEqual(value.title, "AI " + expected)
            XCTAssertTrue(value.detail.contains("AI attention today: " + expected))
        }
    }

    func testPausedIdleAndFailedReportsAreHonest() {
        let paused = AttentionMenuBarPresentation(seconds: 120, paused: true, status: "ChatGPT", problem: nil)
        XCTAssertEqual(paused.title, "AI 2m")
        XCTAssertTrue(paused.detail.contains("Paused"))
        let idle = AttentionMenuBarPresentation(seconds: 120, paused: false, status: "Idle", problem: nil)
        XCTAssertEqual(idle.title, paused.title)
        XCTAssertTrue(idle.detail.contains("Idle"))
        let failure = AttentionMenuBarPresentation(seconds: 120, paused: false, status: "Tracking", problem: "Saving delayed")
        XCTAssertEqual(failure.title, "AI —")
        XCTAssertTrue(failure.detail.contains("Saving delayed"))
    }

    @MainActor func testPublishedTimeFollowsSavedAIOnlyAndResetsAtMidnight() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try ActivityStore(url: directory.appendingPathComponent("test.sqlite"))
        let model = LedgerModel(store: store)
        let midnight = Calendar.current.startOfDay(for: Date())
        let start = midnight.timeIntervalSince1970
        let codex = Observation(app: "Codex", bundle: "com.openai.codex")
        let browser = Observation(app: "Chrome", bundle: "com.google.Chrome")
        var titles = [String]()
        let subscription = model.$today.sink {
            titles.append(AttentionMenuBarPresentation(seconds: $0.ai, paused: false, status: "Tracking", problem: nil).title)
        }
        defer { subscription.cancel() }
        try store.append([Segment(start: start, end: start + 60, observation: codex),
                          Segment(start: start + 60, end: start + 120, observation: browser),
                          Segment(start: start + 120, end: start + 180, observation: .idle)])
        model.refresh(at: midnight.addingTimeInterval(180))
        XCTAssertEqual(titles.last, "AI 1m")
        XCTAssertEqual(model.today.active, 120)
        try store.append([Segment(start: start + 180, end: start + 240, observation: codex)])
        model.refresh(at: midnight.addingTimeInterval(240))
        XCTAssertEqual(titles.last, "AI 2m")
        let nextDay = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: midnight))
        model.refresh(at: nextDay)
        XCTAssertEqual(titles.last, "AI 0s")
        XCTAssertEqual(titles, ["AI 0s", "AI 1m", "AI 2m", "AI 0s"])
        XCTAssertEqual(try store.read().count, 4, "Reporting must preserve history")
    }
}
