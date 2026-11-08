import Foundation

struct AttentionSplit: Equatable {
    var web: Double = 0
    var desktop: Double = 0
    var total: Double { web + desktop }

    static func + (lhs: Self, rhs: Self) -> Self {
        Self(web: lhs.web + rhs.web, desktop: lhs.desktop + rhs.desktop)
    }
}
