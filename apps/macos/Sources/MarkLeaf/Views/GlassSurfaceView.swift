import AppKit

/// A single native-surface seam between MarkLeaf's themed UI and the system.
///
/// macOS 26+ uses the system Liquid Glass effect. Earlier releases and
/// accessibility-friendly configurations keep the previous AppKit material, so
/// callers never branch on an OS version at each UI site.
final class GlassSurfaceView: NSView {
    enum Style {
        case regular
        case clear
        case sidebar
        case interactive

        var glassStyleRawValue: Int? {
            switch self {
            // Matches NSGlassEffectView.Style: regular = 0, clear = 1.
            case .regular, .sidebar, .interactive: return 0
            case .clear: return 1
            }
        }

        var legacyMaterial: NSVisualEffectView.Material {
            switch self {
            case .sidebar: return .sidebar
            case .clear: return .underWindowBackground
            case .regular, .interactive: return .windowBackground
            }
        }
    }

    static let systemSupportsGlass: Bool = {
        if #available(macOS 26, *) { return true }
        return false
    }()

    let style: Style
    private(set) var contentSurface: NSView?
    private var legacyEffectView: NSVisualEffectView?
    private var glassEffectView: AnyObject?
    private var _embedsContentInGlass = false
    private var contentTopConstraint: NSLayoutConstraint?
    private var contentSafeTopConstraint: NSLayoutConstraint?
    private var contentRespectsTopSafeArea = false

    /// Apple only guarantees controls placed in `NSGlassEffectView.contentView`
    /// participate in the glass shape. Standard controls such as segmented
    /// navigations should embed; custom transparent overlays should remain on
    /// top so their hit handling and drawing stay isolated.
    var embedsContentInGlass: Bool {
        get { _embedsContentInGlass }
        set {
            guard _embedsContentInGlass != newValue else { return }
            _embedsContentInGlass = newValue
            rebuildSurface()
        }
    }

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
        GlassSurfaceRegistry.shared.register(self)
        rebuildSurface()
    }

    required init?(coder: NSCoder) {
        style = .regular
        super.init(coder: coder)
        GlassSurfaceRegistry.shared.register(self)
        rebuildSurface()
    }

    deinit {
        GlassSurfaceRegistry.shared.unregister(self)
    }

    func setContent(_ content: NSView) {
        guard contentSurface !== content else { return }
        if let previous = contentSurface {
            previous.removeFromSuperview()
        }
        contentSurface = content
        content.translatesAutoresizingMaskIntoConstraints = false
        rebuildSurface()
    }

    /// Full-height surfaces can paint behind the title bar while their controls
    /// remain below the unsafe strip. The backing keeps its exact edges; only the
    /// content top may be pushed down by the window safe area.
    func setContentRespectsTopSafeArea(_ enabled: Bool) {
        guard contentRespectsTopSafeArea != enabled else { return }
        contentRespectsTopSafeArea = enabled
        updateContentTopConstraints()
    }

    func refresh(forceDark: Bool? = nil) {
        if shouldUseGlass != (glassEffectView != nil) {
            rebuildSurface()
            return
        }
        let dark = forceDark ?? (effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
        let active = window?.isKeyWindow == true
        applyAppearance(dark: dark, active: active, reducedTransparency: reduceTransparency)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refresh()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refresh()
    }

    private var reduceTransparency: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }

    private var shouldUseGlass: Bool {
        Self.systemSupportsGlass && !reduceTransparency
    }

    private func rebuildSurface() {
        glassEffectView?.removeFromSuperview()
        legacyEffectView?.removeFromSuperview()
        contentSurface?.removeFromSuperview()
        glassEffectView = nil
        legacyEffectView = nil

        guard let content = contentSurface else { return }
        contentTopConstraint?.isActive = false
        contentTopConstraint = nil
        contentSafeTopConstraint?.isActive = false
        contentSafeTopConstraint = nil
        if shouldUseGlass, #available(macOS 26, *) {
            let effect = NSGlassEffectView()
            effect.style = NSGlassEffectView.Style(rawValue: style.glassStyleRawValue ?? 0) ?? .regular
            if #available(macOS 27, *) {
                effect.effectIsInteractive = style == .interactive
            }
            effect.translatesAutoresizingMaskIntoConstraints = false
            addSubview(effect)
            glassEffectView = effect
            constrain(effect)
            if embedsContentInGlass {
                effect.contentView = content
            } else {
                addSubview(content, positioned: .above, relativeTo: effect)
                constrainOverlay(content)
            }
        } else {
            let effect = NSVisualEffectView()
            effect.material = style.legacyMaterial
            effect.blendingMode = .behindWindow
            effect.state = .followsWindowActiveState
            effect.wantsLayer = true
            effect.translatesAutoresizingMaskIntoConstraints = false
            addSubview(effect)
            addSubview(content, positioned: .above, relativeTo: effect)
            constrain(effect)
            constrainOverlay(content)
            legacyEffectView = effect
        }
        refresh()
    }

    private func applyAppearance(dark: Bool, active: Bool, reducedTransparency: Bool) {
        let themedAppearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        appearance = themedAppearance
        legacyEffectView?.state = active ? .active : .inactive
        legacyEffectView?.material = reducedTransparency ? .windowBackground : style.legacyMaterial
        guard #available(macOS 26, *) else { return }
        let glassEffectView = self.glassEffectView as? NSGlassEffectView
        glassEffectView?.appearance = themedAppearance
        glassEffectView?.style = reducedTransparency
            ? .clear
            : (NSGlassEffectView.Style(rawValue: style.glassStyleRawValue ?? 0) ?? .regular)
        if #available(macOS 27, *) {
            glassEffectView?.effectIsInteractive = style == .interactive
        }
    }

    private func constrain(_ backing: NSView) {
        NSLayoutConstraint.activate([
            backing.leadingAnchor.constraint(equalTo: leadingAnchor),
            backing.trailingAnchor.constraint(equalTo: trailingAnchor),
            backing.topAnchor.constraint(equalTo: topAnchor),
            backing.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func constrainOverlay(_ content: NSView) {
        let top = content.topAnchor.constraint(equalTo: topAnchor)
        top.priority = .required - 1
        let leading = content.leadingAnchor.constraint(equalTo: leadingAnchor)
        leading.priority = .required - 1
        let trailing = content.trailingAnchor.constraint(equalTo: trailingAnchor)
        trailing.priority = .required - 1
        let bottom = content.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottom.priority = .required - 1
        contentTopConstraint = top
        NSLayoutConstraint.activate([
            leading,
            trailing,
            top,
            bottom,
        ])
        updateContentTopConstraints()
    }

    private func updateContentTopConstraints() {
        guard let content = contentSurface, contentTopConstraint != nil else { return }
        contentSafeTopConstraint?.isActive = false
        contentSafeTopConstraint = nil
        guard contentRespectsTopSafeArea else { return }
        let safeTop = content.topAnchor.constraint(
            greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor
        )
        safeTop.priority = .required
        contentSafeTopConstraint = safeTop
        safeTop.isActive = true
    }
}

/// Keeps long-lived window surfaces in step with accessibility and window
/// activation changes. Surfaces own registration; this registry only holds weak
/// references so window teardown does not retain UI.
final class GlassSurfaceRegistry {
    static let shared = GlassSurfaceRegistry()

    private var surfaces = NSHashTable<AnyObject>.weakObjects()
    private var observers: [NSObjectProtocol] = []

    private init() {
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAll()
        })

        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification] {
            observers.append(NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let window = notification.object as? NSWindow else { return }
                self?.refreshSurfaces(in: window)
            })
        }
    }

    func register(_ surface: GlassSurfaceView) {
        guard !contains(surface) else { return }
        surfaces.add(surface)
    }

    func unregister(_ surface: GlassSurfaceView) {
        surfaces.remove(surface)
    }

    func refreshAll(forceDark: Bool? = nil) {
        for case let surface as GlassSurfaceView in Array(surfaces.allObjects) {
            surface.refresh(forceDark: forceDark)
        }
    }

    func refreshSurfaces(in window: NSWindow) {
        for case let surface as GlassSurfaceView in Array(surfaces.allObjects)
        where surface.window === window {
            surface.refresh()
        }
    }

    private func contains(_ surface: GlassSurfaceView) -> Bool {
        surfaces.allObjects.contains { $0 === surface }
    }
}

/// Attaches a full-window glass backing without making AppKit controls children
/// of NSGlassEffectView. The returned surface remains available for future
/// appearance updates; the host becomes the window's content view.
enum GlassWindowAttachment {
    @discardableResult
    static func attach(
        _ content: NSView,
        to window: NSWindow,
        style: GlassSurfaceView.Style = .interactive
    ) -> GlassSurfaceView {
        let surface = GlassSurfaceView(style: style)
        surface.setContent(content)

        let host = NSView()
        host.wantsLayer = true
        host.addSubview(surface)
        NSLayoutConstraint.activate([
            surface.topAnchor.constraint(equalTo: host.topAnchor),
            surface.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            surface.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            surface.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        window.contentView = host
        return surface
    }
}
