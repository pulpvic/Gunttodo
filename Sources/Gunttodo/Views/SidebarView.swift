import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: TaskStore
    @Binding var selection: TaskScope

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            List(selection: $selection) {
                ForEach(TaskScope.allCases) { scope in
                    Label {
                        HStack {
                            Text(scope.title)
                            Spacer()
                            Text("\(count(for: scope))")
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: scope.systemImage)
                            .foregroundStyle(.secondary)
                    }
                    .tag(scope)
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 44)
            }

            SidebarFooterControls(store: store)
                .padding(.leading, 12)
                .padding(.bottom, 10)
        }
    }

    private func count(for scope: TaskScope) -> Int {
        store.tasks(in: scope, matching: "").count
    }
}

private struct SidebarFooterControls: View {
    @ObservedObject var store: TaskStore

    var body: some View {
        HStack(spacing: 8) {
            SidebarUtilityButton(
                systemImage: store.settings.isOverlayVisible ? "rectangle.on.rectangle" : "rectangle",
                help: store.settings.isOverlayVisible ? "隐藏浮窗" : "显示浮窗"
            ) {
                store.settings.isOverlayVisible.toggle()
            }

            SettingsLink {
                SidebarUtilityButtonLabel(systemImage: "gearshape")
            }
            .buttonStyle(.plain)
            .help("设置")
        }
    }
}

private struct SidebarUtilityButton: View {
    let systemImage: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SidebarUtilityButtonLabel(systemImage: systemImage)
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct SidebarUtilityButtonLabel: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 28, height: 28)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.thinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(0.24), lineWidth: 1)
            }
    }
}
