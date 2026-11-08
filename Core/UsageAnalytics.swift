import Foundation

struct UsageAnalytics {
    var apps = [String: Double]()
    var tools = [String: Double]()
    var active: Double { apps.values.reduce(0, +) }
    var ai: Double { tools.values.reduce(0, +) }

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
                tools[tool, default: 0] += end - start
            }
        }
    }
}
