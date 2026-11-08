import Foundation

enum FeedbackReason: String, CaseIterable, Codable, Sendable {
    case understand, compare, focus, curious, other
    var label: String {
        switch self {
        case .understand: return "Understand my AI habits"
        case .compare: return "Compare the tools I use"
        case .focus: return "Be more intentional with my time"
        case .curious: return "Just curious"
        case .other: return "Something else"
        }
    }
}

enum FeedbackUseCase: String, CaseIterable, Codable, Sendable {
    case coding, research, writing, design, other
    var label: String { rawValue.capitalized }
}

struct FeedbackSubmission: Codable, Equatable, Sendable {
    let id: String
    let schemaVersion: Int
    let reason: FeedbackReason
    let useCase: FeedbackUseCase
    let wish: String
    let appVersion: String
}
