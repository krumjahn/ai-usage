import Foundation

protocol FeedbackSending: Sendable {
    var isConfigured: Bool { get }
    func send(_ submission: FeedbackSubmission) async throws
}

enum FeedbackError: LocalizedError {
    case unavailable, rateLimited, rejected, network
    var errorDescription: String? {
        switch self {
        case .unavailable: return "Online feedback is not connected in this build."
        case .rateLimited: return "Please wait a minute before trying again."
        case .rejected: return "Could not save your answers. Please try again later."
        case .network: return "Could not confirm delivery. Please try again when you’re online."
        }
    }
}

private final class FeedbackRedirectPolicy: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

actor FeedbackClient: FeedbackSending {
    nonisolated let isConfigured: Bool
    private let endpoint: URL?

    static func validEndpoint(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), url.scheme == "https", url.host != nil,
              url.path == "/api/feedback", url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil else { return nil }
        return url
    }

    init(endpoint: URL? = FeedbackClient.validEndpoint(Bundle.main.object(forInfoDictionaryKey: "AIUsageFeedbackEndpoint") as? String)) {
        self.endpoint = endpoint.flatMap { Self.validEndpoint($0.absoluteString) }
        isConfigured = self.endpoint != nil
    }

    func send(_ submission: FeedbackSubmission) async throws {
        guard let endpoint else { throw FeedbackError.unavailable }
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.urlCache = nil
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 20
        let session = URLSession(configuration: config, delegate: FeedbackRedirectPolicy(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(submission)
        let data: Data
        let response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch {
            try Task.checkCancellation()
            throw FeedbackError.network
        }
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse else { throw FeedbackError.rejected }
        if http.statusCode == 429 { throw FeedbackError.rateLimited }
        struct Receipt: Decodable { let ok: Bool; let id: String }
        guard (200...299).contains(http.statusCode), data.count < 4096,
              let receipt = try? JSONDecoder().decode(Receipt.self, from: data),
              receipt.ok, receipt.id.lowercased() == submission.id.lowercased() else { throw FeedbackError.rejected }
    }
}
