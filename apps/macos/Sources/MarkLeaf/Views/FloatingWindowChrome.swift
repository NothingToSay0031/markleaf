import AppKit

/// How a floating window balances native Liquid Glass chrome against a
/// readable body. The classification is owned by the window controller; this
/// helper never guesses from window size or content type.
enum FloatingWindowClassification {
    /// Compact controls and settings; native chrome may use glass, forms stay stable.
    case navigation
    /// Tables, statistics, recovery lists, and export bodies remain opaque.
    case content
    /// System preview chrome with an opaque document preview body.
    case preview
}

extension FloatingWindowClassification: CustomStringConvertible {
    var description: String {
        switch self {
        case .navigation: return "navigation"
        case .content: return "content"
        case .preview: return "preview"
        }
    }
}

/// Shared native floating-window chrome for Liquid Glass.
///
/// Floating windows rely on the system titlebar and toolbar material instead of
/// wrapping their whole body in a translucent blur. The opaque window backing
/// keeps background editor windows from bleeding through on macOS 26/27 and
/// gives earlier systems the same readable fallback.
enum FloatingWindowChrome {
    private static let windows = NSHashTable<NSWindow>.weakObjects()

    static func register(_ window: NSWindow) {
        windows.add(window)
    }

    static func refreshAll(dark: Bool) {
        let appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        for window in windows.allObjects {
            window.appearance = appearance
            window.backgroundColor = .windowBackgroundColor
            window.isOpaque = true
        }
    }

    static func configure(_ window: NSWindow, classification: FloatingWindowClassification) {
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.titlebarSeparatorStyle = titlebarSeparator(for: classification)
        window.isOpaque = true
        window.backgroundColor = .windowBackgroundColor
        window.tabbingMode = .disallowed
        register(window)

        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
    }

    static func titlebarSeparator(for classification: FloatingWindowClassification) -> NSTitlebarSeparatorStyle {
        switch classification {
        case .navigation, .content:
            return .line
        case .preview:
            return .automatic
        }
    }

    /// Installs a body over the opaque system window backing without assigning
    /// a frozen background color. Dynamic colors remain the body's job, while
    /// `NSWindow.backgroundColor` covers any layout inset.
    @discardableResult
    static func installOpaqueBody(_ body: NSView, in window: NSWindow) -> NSView {
        let root = NSView()
        body.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(body)
        window.contentView = root

        NSLayoutConstraint.activate([
            body.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            body.topAnchor.constraint(equalTo: root.topAnchor),
            body.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])

        return root
    }
}
