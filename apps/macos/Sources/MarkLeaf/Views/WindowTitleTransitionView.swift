import AppKit

final class WindowTitleTransitionView: NSView {
    let filenameLabel: NSTextField
    let statusLabel: NSTextField
    private let statusSpaceView = NSView()
    private var statusLeadingConstraint: NSLayoutConstraint!
    private var statusSpaceWidthConstraint: NSLayoutConstraint!
    private var isStatusMarkerVisible = false

    init() {
        filenameLabel = NSTextField(labelWithString: "")
        statusLabel = NSTextField(labelWithString: L10n.t("已修改"))

        super.init(frame: .zero)

        let textFont = NSFont.systemFont(ofSize: 13, weight: .bold)
        filenameLabel.font = textFont
        filenameLabel.textColor = .labelColor
        filenameLabel.lineBreakMode = .byTruncatingMiddle
        filenameLabel.translatesAutoresizingMaskIntoConstraints = false
        filenameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        filenameLabel.setContentHuggingPriority(.required, for: .horizontal)

        statusLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alphaValue = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(filenameLabel)
        addSubview(statusSpaceView)
        addSubview(statusLabel)

        statusSpaceView.translatesAutoresizingMaskIntoConstraints = false
        statusLeadingConstraint = statusSpaceView.leadingAnchor
            .constraint(equalTo: filenameLabel.trailingAnchor, constant: 6)
        statusSpaceWidthConstraint = statusSpaceView.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            filenameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            filenameLabel.topAnchor.constraint(equalTo: topAnchor),
            filenameLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            statusLeadingConstraint,
            statusSpaceWidthConstraint,
            trailingAnchor.constraint(equalTo: statusSpaceView.trailingAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusSpaceView.leadingAnchor),
            statusLabel.firstBaselineAnchor.constraint(equalTo: filenameLabel.firstBaselineAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func setFilename(_ filename: String) {
        filenameLabel.stringValue = filename
    }

    func setStatusMarker(_ label: String, visible: Bool, animated: Bool) {
        statusLabel.stringValue = label
        setStatusVisible(visible, animated: animated)
    }

    private func setStatusVisible(_ visible: Bool, animated: Bool) {
        isStatusMarkerVisible = visible
        let targetAlpha: CGFloat = visible ? 1 : 0
        let targetOffset: CGFloat = visible ? 6 : 0
        let targetWidth = visible ? statusMarkerWidth : 0
        guard animated, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            statusLabel.alphaValue = targetAlpha
            statusLeadingConstraint.constant = targetOffset
            statusSpaceWidthConstraint.constant = targetWidth
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            statusLabel.animator().alphaValue = targetAlpha
            statusLeadingConstraint.animator().constant = targetOffset
            statusSpaceWidthConstraint.animator().constant = targetWidth
        }
    }

    private var statusMarkerWidth: CGFloat {
        ceil(statusLabel.intrinsicContentSize.width)
    }
}
