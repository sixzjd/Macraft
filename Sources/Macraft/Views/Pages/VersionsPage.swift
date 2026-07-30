import SwiftUI

// MARK: - Versions Page
struct VersionsPage: View {
    @Environment(MojangService.self) private var mojang

    @State private var search = ""
    @State private var showReleases = true
    @State private var showSnapshots = false
    @State private var showOld = false

    private var filtered: [MCVersion] {
        mojang.filteredVersions(search: search,
                                showReleases: showReleases,
                                showSnapshots: showSnapshots,
                                showOld: showOld)
    }

    var body: some View {
        PageContainer(title: "版本管理", subtitle: "浏览并安装来自 Mojang 官方的所有 Minecraft 版本") {
            VStack(spacing: MCTheme.Space.lg) {
                toolbar
                content
            }
        }
    }

    private var toolbar: some View {
        Card(padding: MCTheme.Space.lg) {
            HStack(spacing: MCTheme.Space.lg) {
                searchField
                Divider().frame(height: 24).overlay(MCTheme.Palette.border)
                filterToggles
                Spacer()
                GhostButton(title: "刷新", systemImage: "arrow.clockwise") {
                    Task { await mojang.loadManifest() }
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: MCTheme.Space.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(MCTheme.Palette.textTertiary)
            TextField("搜索版本号", text: $search)
                .textFieldStyle(.plain)
                .font(MCTheme.Font.body(13))
                .foregroundStyle(MCTheme.Palette.textPrimary)
        }
        .padding(.horizontal, MCTheme.Space.md)
        .padding(.vertical, MCTheme.Space.sm)
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                .fill(MCTheme.Palette.backgroundDeep)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
        )
    }

    private var filterToggles: some View {
        HStack(spacing: MCTheme.Space.sm) {
            FilterChip(label: "正式版", isOn: $showReleases, tint: MCTheme.Palette.success)
            FilterChip(label: "快照", isOn: $showSnapshots, tint: MCTheme.Palette.warning)
            FilterChip(label: "老旧版本", isOn: $showOld, tint: MCTheme.Palette.textSecondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch mojang.state {
        case .loading, .idle:
            loadingView
        case .failed(let message):
            errorView(message)
        case .loaded:
            versionList
        }
    }

    private var loadingView: some View {
        Card {
            VStack(spacing: MCTheme.Space.lg) {
                ProgressView()
                    .controlSize(.large)
                    .tint(MCTheme.Palette.accent)
                Text("正在获取版本清单…")
                    .font(MCTheme.Font.body(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MCTheme.Space.xxxl)
        }
    }

    private func errorView(_ message: String) -> some View {
        Card {
            VStack(spacing: MCTheme.Space.lg) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 32))
                    .foregroundStyle(MCTheme.Palette.warning)
                Text("无法加载版本清单")
                    .font(MCTheme.Font.headline(15))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
                Text(message)
                    .font(MCTheme.Font.caption(12))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
                    .multilineTextAlignment(.center)
                PrimaryButton(title: "重试", systemImage: "arrow.clockwise") {
                    Task { await mojang.loadManifest() }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MCTheme.Space.xxxl)
        }
    }

    private var versionList: some View {
        VStack(spacing: MCTheme.Space.sm) {
            HStack {
                Text("共 \(filtered.count) 个版本")
                    .font(MCTheme.Font.caption(12))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
                Spacer()
            }
            ForEach(filtered.prefix(200)) { version in
                VersionRow(version: version,
                           isLatestRelease: version.id == mojang.latestRelease)
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    @Binding var isOn: Bool
    var tint: Color

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.12)) { isOn.toggle() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11, weight: .medium))
                Text(label)
                    .font(MCTheme.Font.callout(12))
            }
            .foregroundStyle(isOn ? tint : MCTheme.Palette.textTertiary)
            .padding(.horizontal, MCTheme.Space.md)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(isOn ? tint.opacity(0.08) : MCTheme.Palette.surfaceRaised)
            )
            .overlay(Capsule().strokeBorder(isOn ? tint.opacity(0.3) : MCTheme.Palette.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Version Row
struct VersionRow: View {
    let version: MCVersion
    let isLatestRelease: Bool
    @State private var hovering = false

    var body: some View {
        HStack(spacing: MCTheme.Space.lg) {
            Image(systemName: iconForType)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .fill(MCTheme.Palette.surface)
                        .shadow(color: MCTheme.Palette.shadowSoft, radius: 3, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MCTheme.Space.sm) {
                    Text(version.id)
                        .font(MCTheme.Font.headline(14))
                        .foregroundStyle(MCTheme.Palette.textPrimary)
                    if isLatestRelease {
                        PillBadge(text: "最新正式版", color: MCTheme.Palette.success)
                    }
                }
                Text("\(version.type.displayName) · 发布于 \(version.formattedDate)")
                    .font(MCTheme.Font.caption(12))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
            }

            Spacer()

            GhostButton(title: "安装", systemImage: "arrow.down.circle") { }
                .opacity(hovering ? 1 : 0)
        }
        .padding(MCTheme.Space.lg)
        .background(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .fill(hovering ? MCTheme.Palette.surface : MCTheme.Palette.surfaceRaised)
                .shadow(color: hovering ? MCTheme.Palette.shadowSoft : .clear, radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { self.hovering = hovering }
        }
    }

    private var tint: Color {
        switch version.type {
        case .release:  return MCTheme.Palette.success
        case .snapshot: return MCTheme.Palette.warning
        default:        return MCTheme.Palette.textSecondary
        }
    }

    private var iconForType: String {
        switch version.type {
        case .release:  return "checkmark.seal"
        case .snapshot: return "hammer"
        default:        return "clock"
        }
    }
}
