import AppKit

/// A compact overlay knob shared by document-adjacent AppKit scroll views.
/// It deliberately avoids the legacy full-height scroller track.
final class CompactOverlayScroller: NSScroller {
    static let overlayWidth: CGFloat = 6

    override class var isCompatibleWithOverlayScrollers: Bool { true }

    override class func scrollerWidth(
        for controlSize: NSControl.ControlSize,
        scrollerStyle: NSScroller.Style
    ) -> CGFloat {
        scrollerStyle == .overlay
            ? Self.overlayWidth
            : super.scrollerWidth(for: controlSize, scrollerStyle: scrollerStyle)
    }

    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {}

    override func drawKnob() {
        let knobRect = rect(for: .knob)
        guard knobRect.width > 0, knobRect.height > 0, knobProportion < 1 else { return }
        let thumbRect = NSRect(
            x: knobRect.maxX - 5,
            y: knobRect.minY + 1,
            width: 5,
            height: max(12, knobRect.height - 2)
        )
        NSColor.secondaryLabelColor.withAlphaComponent(0.45).setFill()
        NSBezierPath(roundedRect: thumbRect, xRadius: 2.5, yRadius: 2.5).fill()
    }
}

enum CompactOverlayScrollView {
    static func configure(_ scrollView: NSScrollView) {
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.verticalScroller = CompactOverlayScroller()
    }
}
