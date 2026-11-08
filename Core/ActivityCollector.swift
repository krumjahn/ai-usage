import AppKit
import CoreGraphics

struct Observation: Equatable, Codable {
    var app: String
    var bundle: String
    var domain: String?
    static let idle = Observation(app: "", bundle: "", domain: nil)
}

struct Segment: Codable, Equatable {
    var start: Double
    var end: Double
    var observation: Observation
    var recordedClassification: AIToolClassifier.Match? = nil
}

// Adapted from Brainrot's tick-driven SegmentCoalescer. Delay unconfirmed
// intervals until input resumes or the idle threshold resolves the entire gap.
struct SegmentCoalescer {
    private var lastTime: Double?
    private var previous: Observation?
    private var lastInput: Double = 0
    private var pending = [Segment]()
    let idleThreshold: Double = 120

    mutating func sample(at time: Double, idle: Double, app: Observation?) -> [Segment] {
        let input = min(time, time - max(0, idle))
        defer {
            lastTime = time
            previous = app
            lastInput = input
        }
        guard let start = lastTime, time > start, time - start <= 12 else {
            pending.removeAll()
            return []
        }
        var result = [Segment]()
        // A long gap followed by input between polls still has an idle prefix.
        let returned = input > lastInput + 0.05
        if idle >= idleThreshold || (returned && input - lastInput >= idleThreshold) {
            for var item in pending {
                item.observation = .idle
                result.append(item)
            }
            pending.removeAll()
            let end = returned ? max(start, input) : time
            if end > start { result.append(Segment(start: start, end: end, observation: .idle)) }
            if end < time, let previous {
                pending.append(Segment(start: end, end: time, observation: previous))
            }
            return result
        }
        if let previous {
            pending.append(Segment(start: start, end: time, observation: previous))
        }
        if returned {
            // Split at the last actual input. The trailing interval is provisional.
            let boundary = max(start, input)
            result = pending.filter { $0.start < boundary }.map {
                Segment(start: $0.start, end: min(boundary, $0.end), observation: $0.observation)
            }
            pending = pending.filter { $0.end > boundary }.map {
                Segment(start: max(boundary, $0.start), end: $0.end, observation: $0.observation)
            }
        }
        return result
    }

    mutating func reset() { self = SegmentCoalescer() }
}

enum SystemSampler {
    static func foreground() -> NSRunningApplication? { NSWorkspace.shared.frontmostApplication }
    static func idleSeconds() -> Double {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: UInt32.max)!)
    }
}
