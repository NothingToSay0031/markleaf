import AppKit

/// Owns the selection treatment for MarkLeaf's custom editor tab strip.
///
/// The strip keeps a single shared `GlassSurfaceView`; tab cells never create
/// their own glass layers. A full `NSTabViewController.TabStyle.toolbar`
/// migration is intentionally not used yet because it cannot preserve close
/// buttons, overflow, drag reordering, tear-off, cross-window transfer, and
/// context menus in the current editor shell without behavior loss.
enum EditorTabStripMaterial {
    /// True when the shared strip backing can use current system glass.
    static var supportsSystemSelectionMaterial: Bool {
        GlassSurfaceView.systemSupportsGlass
            && !NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }

    /// The selected-cell fill painted above the shared strip backing. Keeping
    /// it here lets the system treatment evolve without cell code knowing the
    /// macOS version or accessibility state.
    static func selectionBackgroundColor(isActive: Bool) -> CGColor {
        guard isActive else { return NSColor.clear.cgColor }
        return NSColor.controlBackgroundColor.cgColor
    }

    static func titleColor(isActive: Bool) -> NSColor {
        isActive ? .labelColor : .secondaryLabelColor
    }
}
