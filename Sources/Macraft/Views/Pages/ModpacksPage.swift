import SwiftUI

// MARK: - Modpack Model
struct ModpackItem: Identifiable {
    let id = UUID()
    var name: String
    var author: String
    var version: String
    var mcVersion: String
    var modCount: Int
    var downloads: String
    var description: String
    var category: String
    var iconSymbol: String
}

// MARK: - Modpacks Page
struct ModpacksPage: View {
    @State private var modpacks: [ModpackItem] = [
        ModpackItem(name: "All the Mods 9", author: "ATM Team", version: "1.0.30",
                    mcVersion: "1.20.1", modCount: 387, downloads: "12.4M",
                    description: "大型综合科技魔法整合包", category: "综合",
                    iconSymbol: "shippingbox"),
        ModpackItem(name: "Create: Above and Beyond", author: "simibubi", version: "1.4",
                    mcVersion: "1.16.5", modCount: 112, downloads: "5.8M",
                    description: "以 Create 为核心的科技整合包", category: "科技",
                    iconSymbol: "gearshape.2"),
        ModpackItem(name: "Better MC", author: "Sharkie", version: "25.5",
                    mcVersion: "1.20.1", modCount: 220, downloads: "8.1M",
                    description: "原版增强，探索全新世界", category: "冒险",
                    iconSymbol: "mountain.2"),
        ModpackItem(name: "Vault Hunters", author: "Iskall85", version: "3.2",
                    mcVersion: "1.18.2", modCount: 295, downloads: "6.3M",
                    description: "RPG 地牢探索整合包", category: "冒险",
                    iconSymbol: "key"),
    ]
    @State private var search = ""

    private var filtered: [ModpackItem] {
        guard !search.isEmpty else { return modpacks }
        return modpacks.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.description.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        PageContainer(title: "整合包管理", subtitle: "一键安装社区精选整合包，开箱即玩") {
            VStack(spacing: MCTheme.Space.lg) {
                toolbarRow
                modpackGrid
            }
        }
    }

    private var toolbarRow: some View {
        Card(padding: MCTheme.Space.lg) {
            HStack(spacing: MCTheme.Space.lg) {
                HStack(spacing: MCTheme.Space.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(MCTheme.Palette.textTertiary)
                    TextField("搜索整合包", text: $search)
                        .textFieldStyle(.plain)
                        .font(MCTheme.Font.body(13))
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

                Spacer()

                GhostButton(title: "从文件导入", systemImage: "doc.badge.plus") { }
            }
        }
    }

    private var modpackGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: MCTheme.Space.lg)],
                  spacing: MCTheme.Space.lg) {
            ForEach(filtered) { pack in
                ModpackCard(pack: pack)
            }
        }
    }
}

// MARK: - Modpack Card
struct ModpackCard: View {
    let pack: ModpackItem
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
            HStack(spacing: MCTheme.Space.md) {
                Image(systemName: pack.iconSymbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(MCTheme.Palette.accent)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                            .fill(MCTheme.Palette.accentSoft)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.name)
                        .font(MCTheme.Font.headline(14))
                        .foregroundStyle(MCTheme.Palette.textPrimary)
                    Text("by \(pack.author)")
                        .font(MCTheme.Font.caption(11))
                        .foregroundStyle(MCTheme.Palette.textTertiary)
                }
                Spacer()
                PillBadge(text: pack.category, color: MCTheme.Palette.info)
            }

            Text(pack.description)
                .font(MCTheme.Font.body(13))
                .foregroundStyle(MCTheme.Palette.textSecondary)
                .lineLimit(2)

            HStack(spacing: MCTheme.Space.lg) {
                Label("MC \(pack.mcVersion)", systemImage: "cube")
                    .font(MCTheme.Font.caption(11))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
                Label("\(pack.modCount) 模组", systemImage: "puzzlepiece")
                    .font(MCTheme.Font.caption(11))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
                Label(pack.downloads, systemImage: "arrow.down.circle")
                    .font(MCTheme.Font.caption(11))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
            }

            Divider().overlay(MCTheme.Palette.border)

            HStack {
                PrimaryButton(title: "安装", systemImage: "arrow.down.circle") { }
                Spacer()
                GhostButton(title: "详情") { }
            }
        }
        .padding(MCTheme.Space.xl)
        .background(
            RoundedRectangle(cornerRadius: MCTheme.Radius.lg, style: .continuous)
                .fill(MCTheme.Palette.surface)
                .shadow(color: hovering ? MCTheme.Palette.shadowMedium : MCTheme.Palette.shadowSoft,
                        radius: hovering ? 16 : 8, y: hovering ? 6 : 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MCTheme.Radius.lg, style: .continuous)
                .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { self.hovering = hovering }
        }
    }
}
