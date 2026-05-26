import AppKit
import SwiftUI

struct TitlebarAddTaskAccessory: NSViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.action = action
        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.action = action
        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: nsView)
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator: NSObject {
        var action: () -> Void = {}
        private weak var window: NSWindow?
        private var accessory: NSTitlebarAccessoryViewController?

        func installIfNeeded(from probeView: NSView) {
            guard let window = probeView.window else { return }
            guard accessory == nil || self.window !== window else { return }

            uninstall()

            let container = NSView(frame: NSRect(x: 0, y: 0, width: 150, height: 46))
            container.translatesAutoresizingMaskIntoConstraints = false

            let button = CircularTitlebarAddButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.target = self
            button.action = #selector(addTask)
            button.toolTip = "新建任务"

            container.addSubview(button)
            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: 150),
                container.heightAnchor.constraint(equalToConstant: 46),
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 102),
                button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: 30),
                button.heightAnchor.constraint(equalToConstant: 30)
            ])

            let accessory = NSTitlebarAccessoryViewController()
            accessory.layoutAttribute = .left
            accessory.fullScreenMinHeight = 46
            accessory.view = container
            window.addTitlebarAccessoryViewController(accessory)

            self.window = window
            self.accessory = accessory
        }

        func uninstall() {
            guard let window, let accessory else { return }
            if let index = window.titlebarAccessoryViewControllers.firstIndex(of: accessory) {
                window.removeTitlebarAccessoryViewController(at: index)
            }
            self.window = nil
            self.accessory = nil
        }

        @objc private func addTask() {
            action()
        }
    }
}

private final class CircularTitlebarAddButton: NSControl {
    private var isPressed = false {
        didSet { needsDisplay = true }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 30, height: 30)
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let diameter = min(bounds.width, bounds.height)
        let circleRect = NSRect(
            x: bounds.midX - diameter / 2,
            y: bounds.midY - diameter / 2,
            width: diameter,
            height: diameter
        ).insetBy(dx: 0.5, dy: 0.5)

        let circle = NSBezierPath(ovalIn: circleRect)
        (isPressed ? NSColor.controlAccentColor.shadow(withLevel: 0.18) : NSColor.controlAccentColor)?.setFill()
        circle.fill()

        NSColor.white.withAlphaComponent(0.35).setStroke()
        circle.lineWidth = 1
        circle.stroke()

        let plus = NSBezierPath()
        plus.lineWidth = 2
        plus.lineCapStyle = .round
        plus.move(to: NSPoint(x: bounds.midX - 5, y: bounds.midY))
        plus.line(to: NSPoint(x: bounds.midX + 5, y: bounds.midY))
        plus.move(to: NSPoint(x: bounds.midX, y: bounds.midY - 5))
        plus.line(to: NSPoint(x: bounds.midX, y: bounds.midY + 5))

        NSColor.white.setStroke()
        plus.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        isPressed = true
    }

    override func mouseUp(with event: NSEvent) {
        defer { isPressed = false }
        let point = convert(event.locationInWindow, from: nil)
        guard bounds.contains(point) else { return }
        sendAction(action, to: target)
    }
}
