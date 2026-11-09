import Foundation
import Combine

@MainActor final class FeedbackModel: ObservableObject {
    @Published var isPresented = false
    @Published private(set) var isOnboarding = false
    @Published var reason: FeedbackReason?
    @Published var useCase: FeedbackUseCase?
    @Published var wish = ""
    @Published private(set) var sending = false
    @Published private(set) var submitted = false
    @Published private(set) var problem: String?
    private let defaults: UserDefaults
    private let client: any FeedbackSending
    private let version: String
    private var automaticOfferEnabled = false
    private var pending: FeedbackSubmission?
    // A new offer for the launch-first flow, including upgrades from the dashboard-only form.
    static let offeredKey = "feedback.onboarding.offered.v2"
    var isConfigured: Bool { client.isConfigured }
    var shouldOfferOnboarding: Bool {
        automaticOfferEnabled && isConfigured && !isPresented && !defaults.bool(forKey: Self.offeredKey)
    }
    var canSubmit: Bool { isConfigured && reason != nil && useCase != nil && wish.unicodeScalars.count <= 500 && !sending && !submitted }

    init(defaults: UserDefaults = .standard, client: any FeedbackSending = FeedbackClient(),
         version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev") {
        self.defaults = defaults
        self.client = client
        self.version = version
    }
    func activate() { automaticOfferEnabled = true }
    func presentIfNeeded() {
        guard shouldOfferOnboarding else { return }
        present(asOnboarding: true)
    }
    func present(asOnboarding: Bool = false) {
        guard !sending else { return }
        if isConfigured { defaults.set(true, forKey: Self.offeredKey) }
        isOnboarding = asOnboarding
        reason = nil; useCase = nil; wish = ""; problem = nil; submitted = false; pending = nil
        isPresented = true
    }
    func submit() async {
        guard canSubmit, let reason, let useCase else { return }
        let trimmed = wish.trimmingCharacters(in: .whitespacesAndNewlines)
        // Reuse the ID only when retrying exactly the same answers.
        if pending?.reason != reason || pending?.useCase != useCase || pending?.wish != trimmed {
            pending = FeedbackSubmission(id: UUID().uuidString.lowercased(), schemaVersion: 1,
                                         reason: reason, useCase: useCase, wish: trimmed, appVersion: version)
        }
        guard let pending else { return }
        sending = true; problem = nil
        defer { sending = false }
        do {
            try await client.send(pending)
            try Task.checkCancellation()
            submitted = true
            if isOnboarding { isPresented = false }
        } catch is CancellationError {
            // Closing the sheet cancels the attempt without background retries.
        } catch { problem = error.localizedDescription }
    }
}
