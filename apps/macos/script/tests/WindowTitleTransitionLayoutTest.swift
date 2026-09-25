import AppKit

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

let titleView = WindowTitleTransitionView()
expect(
    titleView.filenameLabel.font == NSFont.systemFont(ofSize: 13, weight: .bold),
    "single-tab filenames must match the native titlebar's bold title font"
)
// The filename and marker share one layer so the whole title moves together.
expect(titleView.titleContentViewForTesting.layer != nil, "the title content must be layer-backed for reliable titlebar motion")
expect(
    abs(titleView.titleSlideTransformForTesting.m41 - titleView.titleSlideOffsetForTesting) < 0.5,
    "a fresh title view must start in the hidden-marker slide state so its first modified animation matches later transitions"
)
let startupView = WindowTitleTransitionView()
startupView.titleContentViewForTesting.layer?.transform = CATransform3DIdentity
startupView.applyStartupStateWithoutAnimation()
expect(
    abs(startupView.titleSlideTransformForTesting.m41 - startupView.titleSlideOffsetForTesting) < 0.5,
    "rejoining a window must restore the startup marker offset without animation"
)
titleView.setFilename("笔记.md")
titleView.setStatusMarker("已修改", visible: false, animated: false)
let firstHiddenOffset = titleView.titleSlideTransformForTesting.m41
let firstReservedWidth = titleView.statusSpaceWidthForTesting
titleView.setStatusMarker("已修改", visible: true, animated: false)
let firstVisibleWidth = titleView.statusSpaceWidthForTesting
titleView.setStatusMarker("已修改", visible: false, animated: false)
let laterHiddenOffset = titleView.titleSlideTransformForTesting.m41
print("First/later slide distance: \(firstHiddenOffset) / \(laterHiddenOffset)")
expect(
    abs(firstHiddenOffset - laterHiddenOffset) < 0.5,
    "the first modification must slide the filename as far as subsequent modifications"
)
expect(
    abs(firstReservedWidth - firstVisibleWidth) < 0.5,
    "the first modification must not resize and recenter the title underneath its slide animation"
)
titleView.setStatusMarker("已修改", visible: true, animated: false)
titleView.translatesAutoresizingMaskIntoConstraints = false

let titlebar = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 28))
titlebar.addSubview(titleView)
NSLayoutConstraint.activate([
    titleView.centerXAnchor.constraint(equalTo: titlebar.centerXAnchor),
    titleView.centerYAnchor.constraint(equalTo: titlebar.centerYAnchor),
    titleView.leadingAnchor.constraint(greaterThanOrEqualTo: titlebar.leadingAnchor, constant: 76),
    titleView.trailingAnchor.constraint(lessThanOrEqualTo: titlebar.trailingAnchor, constant: -12),
])
titlebar.layoutSubtreeIfNeeded()

expect(titleView.frame.height >= 16, "the transition view must expose its label height to the title bar")
expect(titleView.filenameLabel.frame.height >= 10, "the filename label must remain visible in the title bar")
expect(titleView.statusLabel.frame.height >= 8, "the status marker must remain visible in the title bar")
expect(
    titleView.filenameLabel.frame.width >= titleView.filenameLabel.intrinsicContentSize.width - 0.5,
    "the filename label must size to its current text"
)

func centerOffset(_ view: NSView, in container: NSView) -> CGFloat {
    abs(view.frame.midX - container.bounds.midX)
}

func alignmentMidX(_ view: NSView, convertedTo container: NSView) -> CGFloat {
    let alignmentFrame = view.alignmentRect(forFrame: view.frame)
    return container.convert(alignmentFrame, from: view.superview!).midX
}
titleView.setStatusMarker("已修改", visible: false, animated: false)
titlebar.layoutSubtreeIfNeeded()
let hiddenTransform = titleView.titleSlideTransformForTesting
expect(
    abs(hiddenTransform.m41 - titleView.titleSlideOffsetForTesting) < 0.5,
    "hiding the marker must apply the stable whole-title slide offset"
)
expect(
    abs(alignmentMidX(titleView.filenameLabel, convertedTo: titlebar)
        + hiddenTransform.m41 - titlebar.bounds.midX) < 0.5,
    "saved filenames must be centered independently of the hidden modified marker"
)

// Switching from a visible read-only marker to the hidden modified fallback
// must not let the hidden fallback's width move the filename. This is the
// exact View > Read Only Mode transition.
titleView.setStatusMarker("只读", visible: true, animated: false)
titlebar.layoutSubtreeIfNeeded()
let readOnlySpaceWidth = titleView.statusSpaceWidthForTesting
titleView.setStatusMarker("已修改", visible: false, animated: false)
titlebar.layoutSubtreeIfNeeded()
expect(
    abs(titleView.statusSpaceWidthForTesting - readOnlySpaceWidth) < 0.5,
    "hiding a read-only marker must not resize the title from its hidden fallback text"
)
expect(
    abs(titleView.titleSlideTransformForTesting.m41 - titleView.titleSlideOffsetForTesting) < 0.5,
    "hiding a read-only marker must use the visible read-only marker's centering width"
)
expect(
    abs(alignmentMidX(titleView.filenameLabel, convertedTo: titlebar)
        + titleView.titleSlideTransformForTesting.m41 - titlebar.bounds.midX) < 0.5,
    "hiding a read-only marker must leave the filename independently centered"
)

titleView.setStatusMarker("已修改", visible: true, animated: false)
titlebar.layoutSubtreeIfNeeded()
let combinedLeading = min(titleView.filenameLabel.frame.minX, titleView.statusLabel.frame.minX)
let combinedTrailing = max(titleView.filenameLabel.frame.maxX, titleView.statusLabel.frame.maxX)
let filenameAlignment = titlebar.convert(
    titleView.filenameLabel.alignmentRect(forFrame: titleView.filenameLabel.frame),
    from: titleView.filenameLabel.superview!
)
let markerAlignment = titlebar.convert(
    titleView.statusLabel.alignmentRect(forFrame: titleView.statusLabel.frame),
    from: titleView.statusLabel.superview!
)
let combinedMidpoint = (
    min(filenameAlignment.minX, markerAlignment.minX)
      + max(filenameAlignment.maxX, markerAlignment.maxX)
) / 2
let visibleTransform = titleView.titleSlideTransformForTesting
expect(abs(visibleTransform.m41) < 0.5, "showing the marker must restore the whole-title position")
expect(
    abs(combinedMidpoint - titlebar.bounds.midX) < 0.5,
    "filename and modified marker must be centered as one group while modified"
)

// Multi-tab MarkLeaf is a fixed application title. It must never reserve the
// hidden marker's width, or its first launch frame starts left of center.
let fixedView = WindowTitleTransitionView()
fixedView.setFixedApplicationTitle("MarkLeaf")
expect(fixedView.statusSpaceWidthForTesting == 0, "fixed application titles must not reserve marker space")
expect(abs(fixedView.titleSlideTransformForTesting.m41) < 0.5, "fixed application titles must remain centered")
expect(fixedView.statusLabel.alphaValue == 0, "fixed application titles must hide the status marker")
fixedView.setDocumentTitle("笔记.md")
expect(fixedView.statusSpaceWidthForTesting > 0, "switching to document mode must restore marker space")
expect(
    abs(fixedView.titleSlideTransformForTesting.m41 - fixedView.titleSlideOffsetForTesting) < 0.5,
    "switching to document mode must restore the stable hidden-marker centering offset"
)

print("PASS")
