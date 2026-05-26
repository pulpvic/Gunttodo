import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: TaskStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button {
            openManager()
        } label: {
            Label("管理任务", systemImage: "sidebar.leading")
        }

        Button {
            store.addTask(title: "新任务", status: .active)
            openManager()
        } label: {
            Label("新建任务", systemImage: "plus")
        }

        Divider()

        Toggle(isOn: $store.settings.isOverlayVisible) {
            Label("显示浮窗", systemImage: "rectangle.on.rectangle")
        }

        Menu {
            Picker("屏幕", selection: $store.settings.overlayScreenIndex) {
                ForEach(Array(NSScreen.screens.enumerated()), id: \.offset) { index, screen in
                    Text(screen.localizedName).tag(index)
                }
            }

            Picker("位置", selection: $store.settings.overlayCorner) {
                ForEach(OverlayCorner.allCases) { corner in
                    Text(corner.title).tag(corner)
                }
            }
        } label: {
            Label("浮窗位置", systemImage: "rectangle.connected.to.line.below")
        }

        Menu {
            Picker("浮窗尺寸", selection: $store.settings.overlaySize) {
                ForEach(OverlaySize.allCases) { size in
                    Text(size.title).tag(size)
                }
            }

            Stepper(value: $store.settings.overlayMaxTasks, in: 1...10) {
                Text("最多 \(store.settings.clampedOverlayMaxTasks) 条")
            }
        } label: {
            Label("浮窗尺寸", systemImage: "arrow.left.and.right")
        }

        SettingsLink {
            Label("偏好设置", systemImage: "slider.horizontal.3")
        }

        Divider()

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("退出 Gunttodo", systemImage: "power")
        }
    }

    private func openManager() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "main")
    }
}
