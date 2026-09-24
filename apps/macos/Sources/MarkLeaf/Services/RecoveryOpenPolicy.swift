import Foundation

enum RecoveryOpenPolicy {
    static let buttonTitle = "打开"

    static func canOpen(isSelected: Bool) -> Bool {
        isSelected
    }

    enum Destination {
        case currentTab
        case newWindow
    }

    static func destination(
        hasActiveWindow: Bool,
        multiTabEnabled: Bool
    ) -> Destination {
        hasActiveWindow && MultiTabModePolicy.allowsTabCreation(isEnabled: multiTabEnabled)
            ? .currentTab
            : .newWindow
    }
}
