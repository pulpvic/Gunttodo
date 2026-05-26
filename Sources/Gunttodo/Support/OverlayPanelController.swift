import AppKit
import SwiftUI

@MainActor
final class OverlayPanelController {
    static let shared = OverlayPanelController()

    private var panel: NSPanel?
    private var hoverTimer: Timer?
    private var isMouseOverPanel = false
    private let edgeMargin = 24.0
    private let dockGap = 12.0

    private init() {}

    func show() {
        if panel == nil {
            panel = makePanel()
        }

        startHoverTracking()
        applySettings()
    }

    func applySettings() {
        guard let panel else { return }
        let settings = TaskStore.shared.settings
        let size = overlaySize(for: settings)
        let origin = origin(for: size, settings: settings)

        panel.ignoresMouseEvents = true
        panel.level = .statusBar
        panel.setFrame(NSRect(origin: origin, size: size), display: true, animate: false)
        panel.alphaValue = targetAlpha(isHovered: isMouseOverPanel)
        panel.contentView?.frame = NSRect(origin: .zero, size: size)

        if settings.isOverlayVisible {
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }

    private func makePanel() -> NSPanel {
        let settings = TaskStore.shared.settings
        let size = overlaySize(for: settings)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        let hostingView = NSHostingView(rootView: OverlayGanttView(store: TaskStore.shared))
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.autoresizingMask = [.width, .height]

        let glassView = NSGlassEffectView(frame: NSRect(origin: .zero, size: size))
        glassView.autoresizingMask = [.width, .height]
        glassView.cornerRadius = 26
        glassView.style = .clear
        glassView.tintColor = NSColor.white.withAlphaComponent(0.04)
        glassView.contentView = hostingView
        panel.contentView = glassView

        return panel
    }

    private func overlaySize(for settings: AppSettings) -> NSSize {
        NSSize(
            width: settings.overlayWidth,
            height: settings.overlayHeight(displayedTaskCount: TaskStore.shared.overlayDisplayedTaskCount)
        )
    }

    private func startHoverTracking() {
        guard hoverTimer == nil else { return }

        let timer = Timer(timeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateHoverState()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        hoverTimer = timer
    }

    private func updateHoverState() {
        guard let panel else { return }
        let settings = TaskStore.shared.settings

        guard settings.isOverlayVisible else {
            isMouseOverPanel = false
            panel.alphaValue = 0
            return
        }

        updateDockAwareFrame(animated: true)

        let hoverFrame = panel.frame.insetBy(dx: -4, dy: -4)
        let isHovering = hoverFrame.contains(NSEvent.mouseLocation)
        guard isHovering != isMouseOverPanel else { return }

        isMouseOverPanel = isHovering
        let alpha = targetAlpha(isHovered: isHovering)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = isHovering ? 0.12 : 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = alpha
        }
    }

    private func targetAlpha(isHovered: Bool) -> CGFloat {
        let requested = TaskStore.shared.settings.overlayOpacity
        let hoverAlpha = min(max(requested, 0.06), 0.24)
        return isHovered ? hoverAlpha : 0.98
    }

    private func updateDockAwareFrame(animated: Bool) {
        guard let panel else { return }
        let settings = TaskStore.shared.settings
        let size = overlaySize(for: settings)
        let origin = origin(for: size, settings: settings)
        let frame = NSRect(origin: origin, size: size)

        guard !panel.frame.isAlmostEqual(to: frame) else { return }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true, animate: false)
        }

        panel.contentView?.frame = NSRect(origin: .zero, size: size)
    }

    private func origin(for size: NSSize, settings: AppSettings) -> NSPoint {
        let screen = selectedScreen(index: settings.overlayScreenIndex)
        let dock = DockConfiguration.current(for: screen)
        let frame = dock.adjustedVisibleFrame
        let x: Double
        let y: Double

        switch settings.overlayCorner {
        case .bottomLeft:
            x = frame.minX + edgeMargin
            y = frame.minY + edgeMargin
        case .bottomRight:
            x = frame.maxX - size.width - edgeMargin
            y = frame.minY + edgeMargin
        case .topLeft:
            x = frame.minX + edgeMargin
            y = frame.maxY - size.height - edgeMargin
        case .topRight:
            x = frame.maxX - size.width - edgeMargin
            y = frame.maxY - size.height - edgeMargin
        }

        return NSPoint(
            x: min(max(x, frame.minX + dockGap), max(frame.maxX - size.width - dockGap, frame.minX + dockGap)),
            y: min(max(y, frame.minY + dockGap), max(frame.maxY - size.height - dockGap, frame.minY + dockGap))
        )
    }

    private func selectedScreen(index: Int) -> NSScreen {
        let screens = NSScreen.screens
        guard screens.indices.contains(index) else {
            return NSScreen.main ?? screens.first ?? NSScreen()
        }

        return screens[index]
    }
}

private enum DockEdge {
    case bottom
    case left
    case right
}

private struct DockConfiguration {
    let screen: NSScreen
    let edge: DockEdge
    let autohides: Bool
    let estimatedThickness: Double
    let gap: Double = 12

    var adjustedVisibleFrame: NSRect {
        var frame = screen.visibleFrame
        guard autohides, isLikelyRevealed else { return frame }

        let screenFrame = screen.frame
        switch edge {
        case .bottom:
            let originalMaxY = frame.maxY
            let safeMinY = screenFrame.minY + estimatedThickness + gap
            frame.origin.y = max(frame.minY, safeMinY)
            frame.size.height = max(0, originalMaxY - frame.minY)
        case .left:
            let originalMaxX = frame.maxX
            let safeMinX = screenFrame.minX + estimatedThickness + gap
            frame.origin.x = max(frame.minX, safeMinX)
            frame.size.width = max(0, originalMaxX - frame.minX)
        case .right:
            let originalMinX = frame.minX
            let safeMaxX = screenFrame.maxX - estimatedThickness - gap
            frame.size.width = max(0, min(frame.maxX, safeMaxX) - originalMinX)
        }

        return frame
    }

    private var isLikelyRevealed: Bool {
        let mouse = NSEvent.mouseLocation
        let frame = screen.frame
        guard frame.insetBy(dx: -2, dy: -2).contains(mouse) else { return false }

        let revealBand = estimatedThickness + 24
        switch edge {
        case .bottom:
            return mouse.y <= frame.minY + revealBand
        case .left:
            return mouse.x <= frame.minX + revealBand
        case .right:
            return mouse.x >= frame.maxX - revealBand
        }
    }

    static func current(for screen: NSScreen) -> DockConfiguration {
        let defaults = UserDefaults(suiteName: "com.apple.dock")
        let orientation = defaults?.string(forKey: "orientation") ?? "bottom"
        let edge: DockEdge

        switch orientation {
        case "left":
            edge = .left
        case "right":
            edge = .right
        default:
            edge = .bottom
        }

        let autohides = defaults?.bool(forKey: "autohide") ?? false
        let tileSize = defaults?.double(forKey: "tilesize") ?? 52
        let visibleThickness = thicknessFromVisibleFrame(screen: screen, edge: edge)
        let estimatedThickness = max(visibleThickness, tileSize + 26, 72)

        return DockConfiguration(
            screen: screen,
            edge: edge,
            autohides: autohides,
            estimatedThickness: estimatedThickness
        )
    }

    private static func thicknessFromVisibleFrame(screen: NSScreen, edge: DockEdge) -> Double {
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame

        switch edge {
        case .bottom:
            return max(0, visibleFrame.minY - screenFrame.minY)
        case .left:
            return max(0, visibleFrame.minX - screenFrame.minX)
        case .right:
            return max(0, screenFrame.maxX - visibleFrame.maxX)
        }
    }
}

private extension NSRect {
    func isAlmostEqual(to other: NSRect) -> Bool {
        abs(origin.x - other.origin.x) < 0.5
            && abs(origin.y - other.origin.y) < 0.5
            && abs(size.width - other.size.width) < 0.5
            && abs(size.height - other.size.height) < 0.5
    }
}
