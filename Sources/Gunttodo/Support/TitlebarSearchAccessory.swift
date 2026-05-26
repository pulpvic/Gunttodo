import AppKit
import SwiftUI

struct TitlebarSearchAccessory: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.text = $text
        context.coordinator.placeholder = placeholder
        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.text = $text
        context.coordinator.placeholder = placeholder
        context.coordinator.updateSearchFieldText(text)
        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: nsView)
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        var text: Binding<String>
        var placeholder = ""
        private weak var window: NSWindow?
        private weak var searchField: NSSearchField?
        private weak var searchButton: FinderTitlebarSearchButton?
        private var accessory: NSTitlebarAccessoryViewController?
        private var popover: NSPopover?

        init(text: Binding<String>) {
            self.text = text
        }

        func installIfNeeded(from probeView: NSView) {
            guard let window = probeView.window else { return }
            if accessory != nil, self.window === window {
                updateSearchFieldText(text.wrappedValue)
                searchField?.placeholderString = placeholder
                return
            }

            uninstall()

            let container = NSView(frame: NSRect(x: 0, y: 0, width: 58, height: 46))
            container.translatesAutoresizingMaskIntoConstraints = false

            let searchButton = FinderTitlebarSearchButton()
            searchButton.translatesAutoresizingMaskIntoConstraints = false
            searchButton.target = self
            searchButton.action = #selector(showSearch)
            searchButton.toolTip = placeholder

            container.addSubview(searchButton)
            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: 58),
                container.heightAnchor.constraint(equalToConstant: 46),
                searchButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
                searchButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                searchButton.widthAnchor.constraint(equalToConstant: 34),
                searchButton.heightAnchor.constraint(equalToConstant: 34)
            ])

            let accessory = NSTitlebarAccessoryViewController()
            accessory.layoutAttribute = .right
            accessory.fullScreenMinHeight = 46
            accessory.view = container
            window.addTitlebarAccessoryViewController(accessory)

            self.window = window
            self.searchButton = searchButton
            self.accessory = accessory
        }

        func updateSearchFieldText(_ newValue: String) {
            guard let searchField, searchField.stringValue != newValue else { return }
            searchField.stringValue = newValue
        }

        func uninstall() {
            guard let window, let accessory else { return }
            if let index = window.titlebarAccessoryViewControllers.firstIndex(of: accessory) {
                window.removeTitlebarAccessoryViewController(at: index)
            }
            popover?.close()
            popover = nil
            self.window = nil
            self.searchField = nil
            self.searchButton = nil
            self.accessory = nil
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            text.wrappedValue = field.stringValue
        }

        @objc private func showSearch() {
            guard let searchButton else { return }

            if let popover, popover.isShown {
                popover.close()
                return
            }

            let popover = NSPopover()
            popover.behavior = .transient
            popover.animates = true

            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 46))
            let field = NSSearchField(frame: .zero)
            field.translatesAutoresizingMaskIntoConstraints = false
            field.placeholderString = placeholder
            field.stringValue = text.wrappedValue
            field.delegate = self
            field.focusRingType = .default

            contentView.addSubview(field)
            NSLayoutConstraint.activate([
                field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
                field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
                field.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                field.heightAnchor.constraint(equalToConstant: 30)
            ])

            let viewController = NSViewController()
            viewController.view = contentView
            popover.contentViewController = viewController
            popover.contentSize = NSSize(width: 300, height: 46)

            self.searchField = field
            self.popover = popover
            popover.show(relativeTo: searchButton.bounds, of: searchButton, preferredEdge: .maxY)

            DispatchQueue.main.async {
                field.window?.makeFirstResponder(field)
            }
        }
    }
}

private final class FinderTitlebarSearchButton: NSControl {
    private var isPressed = false {
        didSet { needsDisplay = true }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 34, height: 34)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let rect = bounds.insetBy(dx: 1, dy: 1)
        let background = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
        (isPressed ? NSColor.white.withAlphaComponent(0.16) : NSColor.white.withAlphaComponent(0.08)).setFill()
        background.fill()

        let center = NSPoint(x: bounds.midX - 2, y: bounds.midY + 1)
        let glassRect = NSRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)
        let glass = NSBezierPath(ovalIn: glassRect)
        glass.lineWidth = 2
        NSColor.secondaryLabelColor.setStroke()
        glass.stroke()

        let handle = NSBezierPath()
        handle.lineWidth = 2
        handle.lineCapStyle = .round
        handle.move(to: NSPoint(x: center.x + 4, y: center.y - 4))
        handle.line(to: NSPoint(x: center.x + 9, y: center.y - 9))
        handle.stroke()
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
