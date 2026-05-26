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
        private var accessory: NSTitlebarAccessoryViewController?

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

            let container = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 46))
            container.translatesAutoresizingMaskIntoConstraints = false

            let searchField = NSSearchField(frame: .zero)
            searchField.translatesAutoresizingMaskIntoConstraints = false
            searchField.placeholderString = placeholder
            searchField.stringValue = text.wrappedValue
            searchField.delegate = self
            searchField.focusRingType = .default

            container.addSubview(searchField)
            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: 380),
                container.heightAnchor.constraint(equalToConstant: 46),
                searchField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
                searchField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                searchField.widthAnchor.constraint(equalToConstant: 340),
                searchField.heightAnchor.constraint(equalToConstant: 30)
            ])

            let accessory = NSTitlebarAccessoryViewController()
            accessory.layoutAttribute = .right
            accessory.fullScreenMinHeight = 46
            accessory.view = container
            window.addTitlebarAccessoryViewController(accessory)

            self.window = window
            self.searchField = searchField
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
            self.window = nil
            self.searchField = nil
            self.accessory = nil
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            text.wrappedValue = field.stringValue
        }
    }
}
