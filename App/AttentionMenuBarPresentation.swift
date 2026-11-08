import Foundation

// Share the same duration formatting and recorded total with the dashboard.
func duration(_ seconds: Double) -> String {
    let n = seconds.isFinite ? Int(max(0, min(seconds, 31_536_000))) : 0
    if n < 60 { return "\(n)s" }
    if n < 3600 { return "\(n / 60)m" }
    return "\(n / 3600)h \((n % 3600) / 60)m"
}

struct AttentionMenuBarPresentation {
    let title: String
    let detail: String
    let symbolName: String?

    init(seconds: Double, paused: Bool, status: String, problem: String?) {
        symbolName = paused ? "pause.fill" : nil
        if let problem {
            title = "—"
            detail = "AI Usage · " + problem
        } else {
            title = duration(seconds)
            detail = "AI attention today: \(duration(seconds)) · \(paused ? "Paused" : status). Recorded foreground time; refreshes every 10 seconds."
        }
    }
}
