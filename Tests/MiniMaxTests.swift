import XCTest
@testable import AttentionLedger

final class MiniMaxTests: XCTestCase {
    func testMiniMaxDesktopAndWebsiteRequireProductEvidence() {
        let desktop = Observation(app: "MiniMax Code", bundle: "com.minimax.agent")
        XCTAssertEqual(AIToolClassifier.classify(desktop).tool, "MiniMax Code")
        XCTAssertEqual(AIToolClassifier.classify(desktop).evidence, "bundle:com.minimax.agent")
        let host = AIToolClassifier.domain(from: "https://agent.minimax.io/chat/private?prompt=secret")
        XCTAssertEqual(host, "agent.minimax.io")
        let browser = Observation(app: "Chrome", bundle: "com.google.Chrome", domain: host)
        XCTAssertEqual(AIToolClassifier.classify(browser).tool, "MiniMax Code")
        for address in ["https://agent.minimax.io.example.com", "https://notagent.minimax.io",
                        "https://platform.minimax.io", "https://minimax.io", "https://project.space.minimax.io"] {
            XCTAssertNil(AIToolClassifier.domain(from: address))
        }
        XCTAssertNil(AIToolClassifier.classify(Observation(app: "MiniMax Code", bundle: "com.apple.Terminal")).tool)
        XCTAssertNil(AIToolClassifier.classify(Observation(app: "Chrome", bundle: "com.google.Chrome")).tool)
    }

    func testExistingMiniMaxActivityIsReclassifiedWithoutChangingEvidence() {
        let original = AIToolClassifier.Match(tool: nil, evidence: "unmatched", version: 5)
        let row = Segment(start: 100, end: 440.1,
                          observation: Observation(app: "MiniMax Code", bundle: "com.minimax.agent"),
                          recordedClassification: original)
        let report = UsageAnalytics([row], from: 0, to: 500)
        XCTAssertEqual(report.tools["MiniMax Code"] ?? 0, 340.1, accuracy: 0.001)
        XCTAssertEqual(report.ai, report.active)
        XCTAssertEqual(row.recordedClassification, original)
    }
}
