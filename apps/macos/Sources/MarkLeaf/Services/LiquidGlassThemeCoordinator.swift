import AppKit

enum ResolvedAppAppearance: Equatable {
    case light
    case dark

    var isDark: Bool { self == .dark }
}

enum LiquidGlassRefreshReason {
    case explicitTheme
    case followSystem
    case systemAppearance
    case windowActivation
    case accessibility

    var canRefreshGlass: Bool { true }
}

final class LiquidGlassThemeCoordinator {
    static let shared = LiquidGlassThemeCoordinator()

    static func resolve(
        followSystem: Bool,
        systemDark: Bool,
        explicitDark: Bool
    ) -> ResolvedAppAppearance {
        if followSystem {
            return systemDark ? .dark : .light
        }
        return explicitDark ? .dark : .light
    }

    func refreshAll(reason: LiquidGlassRefreshReason, forceDark: Bool?) {
        guard reason.canRefreshGlass else { return }
        GlassSurfaceRegistry.shared.refreshAll(forceDark: forceDark)
    }
}
