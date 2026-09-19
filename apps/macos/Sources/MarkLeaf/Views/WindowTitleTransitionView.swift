import AppKit
import QuartzCore

final class WindowTitleTransitionView: NSView {
    let filenameLabel: NSTextField
    let statusLabel: NSTextField
    private let titleContentView = NSView()
    private let statusSpaceView = NSView()
    private var statusLeadingConstraint: NSLayoutConstraint!
    private var statusSpaceWidthConstraint: NSLayoutConstraint!
    private var isStatusMarkerVisible = false

    init() {
        filenameLabel = NSTextField(labelWithString: "")
        statusLabel = NSTextField(labelWithString: L10n.t("已修改"))

        super.init(frame: .zero)
        wantsLayer = true

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
        statusLabel.isHidden = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)

        titleContentView.wantsLayer = true
        titleContentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleContentView)
        titleContentView.addSubview(filenameLabel)
        titleContentView.addSubview(statusSpaceView)
        titleContentView.addSubview(statusLabel)

        statusSpaceView.translatesAutoresizingMaskIntoConstraints = false
        statusLeadingConstraint = statusSpaceView.leadingAnchor
            .constraint(equalTo: filenameLabel.trailingAnchor, constant: 6)
        statusSpaceWidthConstraint = statusSpaceView.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            titleContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleContentView.topAnchor.constraint(equalTo: topAnchor),
            titleContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            filenameLabel.leadingAnchor.constraint(equalTo: titleContentView.leadingAnchor),
            filenameLabel.topAnchor.constraint(equalTo: topAnchor),
            filenameLabel.bottomAnchor.constraint(equalTo: titleContentView.bottomAnchor),
            statusLeadingConstraint,
            statusSpaceWidthConstraint,
            titleContentView.trailingAnchor.constraint(equalTo: statusSpaceView.trailingAnchor),
            statusLabel.leadingAnchor.constraint(
                equalTo: statusSpaceView.leadingAnchor,
                constant: 0
            ),
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
        invalidateIntrinsicContentSize()
        statusSpaceWidthConstraint.constant = statusMarkerWidth
        guard animated, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            statusLabel.alphaValue = targetAlpha
            setTitleSlide(hidden: !visible, animated: false)
            return
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            statusLabel.animator().alphaValue = targetAlpha
        }, completionHandler: nil)
        setTitleSlide(hidden: !visible, animated: true)
    }

    private func setTitleSlide(hidden: Bool, animated: Bool) {
        guard let layer = titleContentView.layer else { return }
        let target = CATransform3DMakeTranslation(hidden ? titleSlideOffset : 0, 0, 0)

        guard animated else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.transform = target
            CATransaction.commit()
            return
        }

        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = NSValue(caTransform3D: layer.transform)
        animation.toValue = NSValue(caTransform3D: target)
        animation.duration = 0.22
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.transform = target
        layer.add(animation, forKey: "markleaf.title.slide")
        CATransaction.commit()
    }

    private var titleSlideOffset: CGFloat {
        (6 + statusMarkerWidth) / 2
    }

    var titleSlideTransformForTesting: CATransform3D {
        titleContentView.layer?.transform ?? CATransform3DIdentity
    }

    var titleSlideOffsetForTesting: CGFloat {
        titleSlideOffset
    }

    var titleContentViewForTesting: NSView {
        titleContentView
    }

    var statusSpaceWidthForTesting: CGFloat {
        statusSpaceWidthConstraint.constant
    }

    private var statusMarkerWidth: CGFloat {
        ceil(statusLabel.intrinsicContentSize.width)
    }
}
