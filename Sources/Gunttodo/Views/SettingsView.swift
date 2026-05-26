import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: TaskStore

    var body: some View {
        Form {
            Section("浮窗") {
                Toggle("显示浮窗", isOn: $store.settings.isOverlayVisible)

                TextField("天气城市", text: $store.settings.weatherCity)
                    .textFieldStyle(.roundedBorder)

                Slider(value: $store.settings.overlayOpacity, in: 0.06...0.24) {
                    Text("悬停透明度")
                } minimumValueLabel: {
                    Text("隐")
                } maximumValueLabel: {
                    Text("显")
                }
            }

            Section("浮窗位置") {
                Picker("显示屏", selection: $store.settings.overlayScreenIndex) {
                    ForEach(Array(NSScreen.screens.enumerated()), id: \.offset) { index, screen in
                        Text(screen.localizedName).tag(index)
                    }
                }

                Picker("角落", selection: $store.settings.overlayCorner) {
                    ForEach(OverlayCorner.allCases) { corner in
                        Text(corner.title).tag(corner)
                    }
                }
            }

            Section("浮窗尺寸") {
                Picker("浮窗尺寸", selection: $store.settings.overlaySize) {
                    ForEach(OverlaySize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }

                Stepper(value: $store.settings.overlayMaxTasks, in: 1...10) {
                    Text("最多展示 \(store.settings.clampedOverlayMaxTasks) 条任务")
                }
            }

            if let error = store.lastError {
                Section("存储") {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
    }
}
