import AppKit

/// Owns the capability decision for MarkLeaf's custom editor tab strip.
///
/// The strip keeps one shared native glass backing; active cells use a light
/// translucent selection capsule without adding another glass layer. A full
/// `NSTabViewController.TabStyle.toolbar` migration
/// is intentionally not used yet because it cannot preserve close buttons,
/// overflow, drag reordering, tear-off, cross-window transfer, and context
/// menus in the current editor shell without behavior loss.
enum EditorTabStripMaterial {
    /// True when the shared strip backing can use current system glass.
    static var supportsSystemSelectionMaterial: Bool {
        GlassSurfaceView.systemSupportsGlass
            && !NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }

    static func titleColor(isActive: Bool) -> NSColor {
        isActive ? .labelColor : .secondaryLabelColor
    }
}
