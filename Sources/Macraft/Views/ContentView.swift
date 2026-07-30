import SwiftUI

// MARK: - Navigation Tabs
enum NavTab: String, CaseIterable, Identifiable {
    case home      = "首页"
    case instances = "实例"
    case versions  = "版本"
    case mods      = "模组"
    case resourcePacks = "资源包"
    case modpacks  = "整合包"
    case accounts  = "账户"
    case downloads = "下载"
    case settings  = "设置"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home:          return "house"
        case .instances:     return "square.stack.3d.up"
        case .versions:      return "cube"
        case .mods:          return "puzzlepiece"
        case .resourcePacks: return "paintpalette"
        case .modpacks:      return "shippingbox"
        case .accounts:      return "person.circle"
        case .downloads:     return "arrow.down.circle"
        case .settings:      return "gearshape"
        }
    }

    static let primary: [NavTab] = [.home, .instances, .versions]
    static let content: [NavTab] = [.mods, .resourcePacks, .modpacks]
    static let system: [NavTab] = [.accounts, .downloads, .settings]
}

// MARK: - Content View (shell)
struct ContentView: View {
    @Environment(MojangService.self) private var mojang
    @State private var selectedTab: NavTab = .home

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(selectedTab: $selectedTab)
                .frame(width: 220)

            Divider().overlay(MCTheme.Palette.border)

            ZStack {
                AppBackground()
                detail
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(MCTheme.Palette.background)
        .preferredColorScheme(.light)
        .task {
            if mojang.state == .idle {
                await mojang.loadManifest()
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        Group {
            switch selectedTab {
            case .home:          HomePage(selectedTab: $selectedTab)
            case .instances:     InstancesPage()
            case .versions:      VersionsPage()
            case .mods:          ModsPage()
            case .resourcePacks: ResourcePacksPage()
            case .modpacks:      ModpacksPage()
            case .accounts:      AccountsPage()
            case .downloads:     DownloadsPage()
            case .settings:      SettingsPage()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Sidebar
struct Sidebar: View {
    @Binding var selectedTab: NavTab

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.horizontal, MCTheme.Space.xl)
                .padding(.top, MCTheme.Space.xxl)
                .padding(.bottom, MCTheme.Space.xl)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: MCTheme.Space.xl) {
                    navGroup(title: nil, tabs: NavTab.primary)
                    navGroup(title: "内容", tabs: NavTab.content)
                    navGroup(title: "系统", tabs: NavTab.system)
                }
                .padding(.horizontal, MCTheme.Space.md)
            }

            Spacer()

            footer
                .padding(.horizontal, MCTheme.Space.md)
                .padding(.bottom, MCTheme.Space.lg)
        }
        .frame(maxHeight: .infinity)
        .background(MCTheme.Palette.surface)
    }

    private var brand: some View {
        HStack(spacing: MCTheme.Space.md) {
            Image(systemName: "cube.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(MCTheme.Palette.accent)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .fill(MCTheme.Palette.accentSoft)
                )
            VStack(alignment: .leading, spacing: 1) {
                Text("Macraft")
                    .font(MCTheme.Font.brand(17))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
                Text("macOS 启动器")
                    .font(MCTheme.Font.caption(11))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
            }
        }
    }

    private func navGroup(title: String?, tabs: [NavTab]) -> some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.xs) {
            if let title {
                Text(title)
                    .font(MCTheme.Font.caption(11).weight(.medium))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
                    .padding(.horizontal, MCTheme.Space.md)
                    .padding(.bottom, 2)
            }
            ForEach(tabs) { tab in
                SidebarRow(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: MCTheme.Space.md) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(MCTheme.Palette.textTertiary)
            VStack(alignment: .leading, spacing: 1) {
                Text("离线玩家")
                    .font(MCTheme.Font.callout(13))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
                Text("未登录正版")
                    .font(MCTheme.Font.caption(11))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
            }
            Spacer()
        }
        .padding(MCTheme.Space.md)
        .background(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .fill(MCTheme.Palette.surfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
        )
    }
}

// MARK: - Sidebar Row
struct SidebarRow: View {
    let tab: NavTab
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: MCTheme.Space.md) {
                Image(systemName: isSelected ? tab.icon + ".fill" : tab.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? MCTheme.Palette.accent : MCTheme.Palette.textSecondary)
                    .frame(width: 20)
                Text(tab.rawValue)
                    .font(MCTheme.Font.callout(13))
                    .foregroundStyle(isSelected ? MCTheme.Palette.textPrimary : MCTheme.Palette.textSecondary)
                Spacer()
            }
            .padding(.horizontal, MCTheme.Space.md)
            .padding(.vertical, MCTheme.Space.sm + 1)
            .background(
                RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                    .fill(rowBackground)
            )
            .contentShape(RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { self.hovering = hovering }
        }
    }

    private var rowBackground: Color {
        if isSelected {
            return MCTheme.Palette.accentSoft
        } else if hovering {
            return MCTheme.Palette.surfaceHover
        } else {
            return .clear
        }
    }
}
