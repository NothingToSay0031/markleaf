import Foundation

enum GlassRefreshTrigger {
    case windowAttached
    case appearanceChanged
    case themeChanged
    case accessibilityChanged
    case keyWindowChanged

    case caretMoved
    case selectionChanged
    case contentChanged
    case scrolled
    case viewportResized
}

enum LiquidGlassPerformancePolicy {
    /// Glass owns the window shell only. Editor hot paths must never ask the
    /// window shell to invalidate blur, layout, or appearance.
    static func shouldRefresh(_ trigger: GlassRefreshTrigger) -> Bool {
        switch trigger {
        case .windowAttached, .appearanceChanged, .themeChanged,
             .accessibilityChanged, .keyWindowChanged:
            return true
        case .caretMoved, .selectionChanged, .contentChanged,
             .scrolled, .viewportResized:
            return false
        }
    }
}
