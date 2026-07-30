import SwiftUI

// MARK: - Page Container
/// 统一的页面外壳：标题栏 + 可滚动内容区
struct PageContainer<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: MCTheme.Space.xs) {
                Text(title)
                    .font(MCTheme.Font.display(26))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(MCTheme.Font.body(13))
                        .foregroundStyle(MCTheme.Palette.textTertiary)
                }
            }
            .padding(.horizontal, MCTheme.Space.xxxl)
            .padding(.top, MCTheme.Space.xxl)
            .padding(.bottom, MCTheme.Space.xl)

            ScrollView {
                content
                    .padding(.horizontal, MCTheme.Space.xxxl)
                    .padding(.bottom, MCTheme.Space.xxxl)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Home Page
struct HomePage: View {
    @Environment(MojangService.self) private var mojang
    @Binding var selectedTab: NavTab

    var body: some View {
        PageContainer(title: "欢迎回来", subtitle: "准备好进入方块世界了吗？") {
            VStack(spacing: MCTheme.Space.xl) {
                launchCard
                statsRow
                quickRow
            }
        }
    }

    private var launchCard: some View {
        Card(padding: MCTheme.Space.xxl) {
            HStack(spacing: MCTheme.Space.xxl) {
                VStack(alignment: .leading, spacing: MCTheme.Space.md) {
                    PillBadge(text: mojang.latestRelease.isEmpty ? "加载中" : "最新 \(mojang.latestRelease)")
                    Text("启动 Minecraft")
                        .font(MCTheme.Font.display(26))
                        .foregroundStyle(MCTheme.Palette.textPrimary)
                    Text("选择版本，一键进入游戏。支持正式版、快照与历史版本。")
                        .font(MCTheme.Font.body(14))
                        .foregroundStyle(MCTheme.Palette.textSecondary)
                        .frame(maxWidth: 400, alignment: .leading)
                    HStack(spacing: MCTheme.Space.md) {
                        PrimaryButton(title: "立即启动", systemImage: "play.fill") { }
                        GhostButton(title: "管理版本", systemImage: "slider.horizontal.3") {
                            selectedTab = .versions
                        }
                    }
                    .padding(.top, MCTheme.Space.sm)
                }
                Spacer()
                launchArt
            }
        }
    }

    private var launchArt: some View {
        Image(systemName: "cube.fill")
            .font(.system(size: 72, weight: .light))
            .foregroundStyle(MCTheme.Palette.accent.opacity(0.15))
            .frame(width: 140, height: 140)
            .background(
                RoundedRectangle(cornerRadius: MCTheme.Radius.xl, style: .continuous)
                    .fill(MCTheme.Palette.accentSoft)
            )
            .padding(.trailing, MCTheme.Space.lg)
    }

    private var statsRow: some View {
        HStack(spacing: MCTheme.Space.lg) {
            StatTile(label: "正式版本", value: "\(mojang.releaseCount)",
                     systemImage: "checkmark.seal", tint: MCTheme.Palette.success)
            StatTile(label: "快照版本", value: "\(mojang.snapshotCount)",
                     systemImage: "hammer", tint: MCTheme.Palette.warning)
            StatTile(label: "全部版本", value: "\(mojang.allVersions.count)",
                     systemImage: "square.stack.3d.up", tint: MCTheme.Palette.info)
            StatTile(label: "已安装", value: "0",
                     systemImage: "internaldrive", tint: MCTheme.Palette.accent)
        }
    }

    private var quickRow: some View {
        Card {
            VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
                SectionHeader(title: "快捷操作")
                HStack(spacing: MCTheme.Space.md) {
                    QuickAction(title: "添加账户", icon: "person.badge.plus", tab: .accounts,
                                selectedTab: $selectedTab)
                    QuickAction(title: "下载中心", icon: "arrow.down.circle", tab: .downloads,
                                selectedTab: $selectedTab)
                    QuickAction(title: "全局设置", icon: "gearshape", tab: .settings,
                                selectedTab: $selectedTab)
                }
            }
        }
    }
}

struct QuickAction: View {
    let title: String
    let icon: String
    let tab: NavTab
    @Binding var selectedTab: NavTab
    @State private var hovering = false

    var body: some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: MCTheme.Space.md) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(MCTheme.Palette.accent)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                            .fill(MCTheme.Palette.surface)
                            .shadow(color: MCTheme.Palette.shadowSoft, radius: 4, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                            .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
                    )
                Text(title)
                    .font(MCTheme.Font.callout(12))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MCTheme.Space.lg)
            .background(
                RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                    .fill(hovering ? MCTheme.Palette.surfaceHover : MCTheme.Palette.surfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                    .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { self.hovering = hovering }
        }
    }
}
