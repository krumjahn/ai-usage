import XCTest
@testable import AttentionLedger

private actor FeedbackStub: FeedbackSending {
    nonisolated let isConfigured: Bool
    var values = [FeedbackSubmission]()
    var fail = false
    init(configured: Bool = true) { isConfigured = configured }
    func setFailure(_ value: Bool) { fail = value }
    func send(_ submission: FeedbackSubmission) async throws {
        values.append(submission)
        if fail { throw FeedbackError.network }
    }
}

final class FeedbackTests: XCTestCase {
    @MainActor func testOnlyConfiguredActivatedBuildOffersOnceAndSkipSendsNothing() async {
        let suite = "feedback-tests-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let client = FeedbackStub()
        let model = FeedbackModel(defaults: defaults, client: client)
        model.presentIfNeeded()
        XCTAssertFalse(model.isPresented)
        model.activate(); model.presentIfNeeded()
        XCTAssertTrue(model.isPresented)
        model.isPresented = false
        model.presentIfNeeded()
        XCTAssertFalse(model.isPresented)
        let values = await client.values
        XCTAssertTrue(values.isEmpty)
        let disabled = FeedbackModel(defaults: defaults, client: FeedbackStub(configured: false))
        defaults.removeObject(forKey: FeedbackModel.offeredKey)
        disabled.activate(); disabled.presentIfNeeded()
        XCTAssertFalse(disabled.isPresented)
        XCTAssertFalse(disabled.canSubmit)
        disabled.present()
        XCTAssertFalse(defaults.bool(forKey: FeedbackModel.offeredKey))
    }

    @MainActor func testExplicitSubmissionMinimalPayloadAndRetryIdentity() async throws {
        let suite = "feedback-tests-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let client = FeedbackStub()
        let model = FeedbackModel(defaults: defaults, client: client, version: "0.1.0")
        model.present()
        XCTAssertFalse(model.canSubmit)
        model.reason = .understand; model.useCase = .coding
        model.wish = String(repeating: "🧠", count: 501)
        XCTAssertFalse(model.canSubmit)
        model.wish = "  Weekly comparison  "
        await client.setFailure(true)
        await model.submit()
        XCTAssertNotNil(model.problem)
        XCTAssertFalse(model.submitted)
        await model.submit()
        var values = await client.values
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0].id, values[1].id)
        model.wish = "A new answer"
        await client.setFailure(false)
        await model.submit()
        values = await client.values
        XCTAssertNotEqual(values[1].id, values[2].id)
        XCTAssertTrue(model.submitted)
        XCTAssertFalse(model.canSubmit)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(values[0])) as? [String: Any])
        XCTAssertEqual(Set(object.keys), Set(["id", "schemaVersion", "reason", "useCase", "wish", "appVersion"]))
        XCTAssertEqual(object["wish"] as? String, "Weekly comparison")
        XCTAssertEqual(object["appVersion"] as? String, "0.1.0")
    }

    func testEndpointRejectsInsecureOrDecoratedURLs() {
        XCTAssertNotNil(FeedbackClient.validEndpoint("https://example.com/api/feedback"))
        for value in [nil, "", "http://example.com/api/feedback", "https://example.com/", "https://a:b@example.com/api/feedback", "https://example.com/api/feedback?secret=x", "https://example.com/api/feedback#x"] as [String?] {
            XCTAssertNil(FeedbackClient.validEndpoint(value))
        }
    }
}
