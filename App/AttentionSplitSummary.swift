import SwiftUI

struct AttentionSplitSummary: View {
    let split: AttentionSplit

    static func description(_ split: AttentionSplit) -> String {
        "Web \(duration(split.web)) · Desktop \(duration(split.desktop))"
    }

    var body: some View {
        Text(Self.description(split))
            .font(.caption).monospacedDigit().foregroundStyle(.secondary)
            .lineLimit(1).minimumScaleFactor(0.8)
            .help("Recorded foreground time, split by source. Background tabs and agents are not counted.")
    }
}
