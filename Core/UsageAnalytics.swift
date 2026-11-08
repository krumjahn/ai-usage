import Foundation

struct UsageAnalytics {
    var apps = [String: Double]()
    private(set) var toolSplits = [String: AttentionSplit]()
    var tools: [String: Double] { toolSplits.mapValues(\.total) }
    var split: AttentionSplit { toolSplits.values.reduce(AttentionSplit(), +) }
    var active: Double { apps.values.reduce(0, +) }
    var ai: Double { split.total }

    init(_ segments: [Segment] = [], from: Double = 0, to: Double = 0) {
        var cursor = from
        for row in segments.sorted(by: { $0.start < $1.start }) {
            let start = max(cursor, row.start)
            let end = min(to, row.end)
            guard start < end else { continue }
            cursor = end
            guard row.observation != .idle else { continue }
            apps[row.observation.app, default: 0] += end - start
            if let tool = AIToolClassifier.classify(row.observation).tool {
                // Split only the same confirmed, deduplicated AI intervals used
                // for the combined total. Ordinary browsing never reaches here.
                if BrowserAdapter.supported.contains(row.observation.bundle) {
                    toolSplits[tool, default: AttentionSplit()].web += end - start
                } else {
                    toolSplits[tool, default: AttentionSplit()].desktop += end - start
                }
            }
        }
    }
}
