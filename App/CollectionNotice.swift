import Foundation

enum CollectionNotice {
    static func text(paused: Bool, status: String) -> String? {
        if paused { return "Paused" }
        switch status {
        case "Idle", "Session inactive": return status
        default: return nil
        }
    }
}
