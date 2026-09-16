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
titleView.setFilename("笔记.md")
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

titleView.setStatusMarker("已修改", visible: false, animated: false)
titlebar.layoutSubtreeIfNeeded()

func alignmentMidX(_ view: NSView, convertedTo container: NSView) -> CGFloat {
    let alignmentFrame = view.alignmentRect(forFrame: view.frame)
    return container.convert(alignmentFrame, from: view.superview!).midX
}
expect(
    abs(alignmentMidX(titleView.filenameLabel, convertedTo: titlebar) - titlebar.bounds.midX) < 0.5,
    "saved filenames must be centered independently of the hidden modified marker"
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
expect(
    abs(combinedMidpoint - titlebar.bounds.midX) < 0.5,
    "filename and modified marker must be centered as one group while modified"
)

print("PASS")
