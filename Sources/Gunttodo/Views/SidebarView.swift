import AppKit
import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: TaskStore
    @Binding var selection: TaskScope

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            FinderSidebarMaterial()
                .ignoresSafeArea()

            Rectangle()
                .fill(.black.opacity(0.46))
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 4) {
                ForEach(TaskScope.allCases) { scope in
                    FinderSidebarRow(
                        scope: scope,
                        count: count(for: scope),
                        isSelected: selection == scope
                    ) {
                        selection = scope
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .padding(.top, 22)
            .padding(.bottom, 56)

            SidebarFooterControls(store: store)
                .padding(.leading, 12)
                .padding(.bottom, 11)
        }
    }

    private func count(for scope: TaskScope) -> Int {
        store.tasks(in: scope, matching: "").count
    }
}

private struct FinderSidebarMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = .sidebar
        nsView.blendingMode = .behindWindow
        nsView.state = .active
    }
}

private struct FinderSidebarRow: View {
    let scope: TaskScope
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    private var selectedForeground: Color {
        Color(nsColor: .controlAccentColor)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: scope.systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? selectedForeground : .secondary)
                    .frame(width: 20)

                Text(scope.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? selectedForeground : .secondary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text("\(count)")
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .frame(height: 31)
            .padding(.horizontal, 9)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.white.opacity(0.10))
                }
            }
        }
        .buttonStyle(.plain)
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
            .foregroundStyle(.secondary)
            .frame(width: 30, height: 30)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.08))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
    }
}
