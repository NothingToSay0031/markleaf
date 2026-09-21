import AppKit

enum AppAppearancePolicy {
    /// `nil` means inherit the system. Manual color themes must therefore keep
    /// an explicit light override; otherwise floating windows follow a dark
    /// system while the main editor switches to a light theme.
    static func appearanceName(themeIsDark: Bool, followsSystem: Bool) -> NSAppearance.Name? {
        guard !followsSystem else { return nil }
        return themeIsDark ? NSAppearance.Name.darkAqua : NSAppearance.Name.aqua
    }
}
