import Foundation

enum EditorHostTransitionPolicy {
    static func shouldAnimate(
        from previousTabID: String?,
        to targetTabID: String,
        requested: Bool,
        reduceMotion: Bool,
        targetHasThemedFrame: Bool = true
    ) -> Bool {
        requested && targetHasThemedFrame && !reduceMotion
            && previousTabID != nil && previousTabID != targetTabID
    }
}
