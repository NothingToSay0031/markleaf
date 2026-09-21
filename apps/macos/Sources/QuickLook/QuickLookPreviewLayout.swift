import CoreGraphics

enum QuickLookPreviewLayout {
    static func contentSize(visible: CGSize?) -> CGSize {
        guard let visible else { return CGSize(width: 680, height: 500) }
        return CGSize(
            width: min(720, max(480, visible.width * 0.55)),
            height: min(560, max(360, visible.height * 0.58))
        )
    }
}
