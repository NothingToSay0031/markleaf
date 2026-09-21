import Foundation

enum MultiTabModePolicy {
    static func showsTabBar(isEnabled: Bool) -> Bool {
        isEnabled
    }

    static func allowsTabCreation(isEnabled: Bool) -> Bool {
        isEnabled
    }

    static func workspacePrefersNewTab(
        workspacePreference: Bool,
        multiTabEnabled: Bool
    ) -> Bool {
        workspacePreference && multiTabEnabled
    }

    static func externalFileMode(
        _ mode: ExternalFileOpenMode,
        multiTabEnabled: Bool
    ) -> ExternalFileOpenMode {
        guard !multiTabEnabled, mode == .newTab else { return mode }
        return .currentWindow
    }

    static func externalNewTabItemEnabled(multiTabEnabled: Bool) -> Bool {
        multiTabEnabled
    }

    static func workspaceControlsEnabled(multiTabEnabled: Bool) -> Bool {
        multiTabEnabled
    }

    /// Disabled single-document mode keeps the canonical default visible; the
    /// routing policy still replaces the current document at runtime.
    static func workspaceDisplayPrefersNewTab(
        saved: Bool,
        multiTabEnabled: Bool
    ) -> Bool {
        multiTabEnabled ? saved : true
    }
}
