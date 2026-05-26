import SwiftUI

@main
@MainActor
struct GunttodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = TaskStore.shared

    var body: some Scene {
        Window("", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 680, minHeight: 620)
                .toolbar(removing: .title)
                .containerBackground(.ultraThinMaterial, for: .window)
        }
        .defaultSize(width: 1080, height: 680)

        MenuBarExtra {
            MenuBarView(store: store)
        } label: {
            Label("Gunttodo", systemImage: "chart.bar.xaxis")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(store: store)
                .frame(width: 420)
                .padding(24)
        }
    }
}
