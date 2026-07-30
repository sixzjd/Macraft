import SwiftUI

// MARK: - Mod Model
struct ModItem: Identifiable {
    let id = UUID()
    var name: String
    var author: String
    var version: String
    var description: String
    var category: String
    var isEnabled: Bool
    var iconSymbol: String
}

// MARK: - Mods Page
struct ModsPage: View {
    @State private var mods: [ModItem] = [
        ModItem(name: "Sodium", author: "CaffeineMC", version: "0.6.5",
                description: "现代渲染引擎，大幅提升帧率", category: "性能优化",
                isEnabled: true, iconSymbol: "gauge.with.dots.needle.67percent"),
        ModItem(name: "Lithium", author: "CaffeineMC", version: "0.13.1",
                description: "服务端游戏逻辑优化", category: "性能优化",
                isEnabled: true, iconSymbol: "atom"),
        ModItem(name: "Iris Shaders", author: "coderbot", version: "1.8.1",
                description: "兼容 Sodium 的光影加载器", category: "视觉",
                isEnabled: true, iconSymbol: "sun.max"),
        ModItem(name: "JEI", author: "mezz", version: "19.21.0",
                description: "物品与合成表浏览器", category: "实用工具",
                isEnabled: true, iconSymbol: "book"),
        ModItem(name: "Create", author: "simibubi", version: "0.5.1",
                description: "机械与自动化模组", category: "科技",
                isEnabled: false, iconSymbol: "gearshape.2"),
        ModItem(name: "Xaero's Minimap", author: "xaero96", version: "24.6.1",
                description: "小地图与路径点", category: "实用工具",
                isEnabled: true, iconSymbol: "map"),
    ]
    @State private var search = ""
    @State private var selectedCategory = "全部"

    private var categories: [String] {
        ["全部"] + Array(Set(mods.map(\.category))).sorted()
    }

    private var filtered: [ModItem] {
        mods.filter { mod in
            let matchSearch = search.isEmpty ||
                mod.name.localizedCaseInsensitiveContains(search) ||
                mod.description.localizedCaseInsensitiveContains(search)
            let matchCategory = selectedCategory == "全部" || mod.category == selectedCategory
            return matchSearch && matchCategory
        }
    }

    var body: some View {
        PageContainer(title: "模组管理", subtitle: "管理当前实例已安装的模组（Fabric / Forge / NeoForge）") {
            VStack(spacing: MCTheme.Space.lg) {
                toolbarRow
                modList
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
                    TextField("搜索模组", text: $search)
                        .textFieldStyle(.plain)
                        .font(MCTheme.Font.body(13))
                }
                .padding(.horizontal, MCTheme.Space.md)
                .padding(.vertical, MCTheme.Space.sm)
                .frame(width: 200)
                .background(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .fill(MCTheme.Palette.backgroundDeep)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
                )

                Divider().frame(height: 24).overlay(MCTheme.Palette.border)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MCTheme.Space.sm) {
                        ForEach(categories, id: \.self) { cat in
                            FilterChip(label: cat,
                                       isOn: .constant(selectedCategory == cat),
                                       tint: MCTheme.Palette.accent)
                                .onTapGesture {
                                    withAnimation(.easeOut(duration: 0.12)) {
                                        selectedCategory = cat
                                    }
                                }
                        }
                    }
                }

                Spacer()

                GhostButton(title: "安装模组", systemImage: "plus") { }
            }
        }
    }

    private var modList: some View {
        VStack(spacing: MCTheme.Space.sm) {
            HStack {
                Text("\(filtered.count) 个模组 · \(mods.filter(\.isEnabled).count) 个已启用")
                    .font(MCTheme.Font.caption(12))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
                Spacer()
            }
            ForEach(filtered) { mod in
                ModRow(mod: mod) { index in
                    if let i = mods.firstIndex(where: { $0.id == index }) {
                        mods[i].isEnabled.toggle()
                    }
                }
            }
        }
    }
}

// MARK: - Mod Row
struct ModRow: View {
    let mod: ModItem
    let onToggle: (UUID) -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: MCTheme.Space.lg) {
            Image(systemName: mod.iconSymbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(mod.isEnabled ? MCTheme.Palette.accent : MCTheme.Palette.textTertiary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .fill(mod.isEnabled ? MCTheme.Palette.accentSoft : MCTheme.Palette.surfaceRaised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MCTheme.Space.sm) {
                    Text(mod.name)
                        .font(MCTheme.Font.headline(14))
                        .foregroundStyle(MCTheme.Palette.textPrimary)
                    Text("v\(mod.version)")
                        .font(MCTheme.Font.mono(11))
                        .foregroundStyle(MCTheme.Palette.textTertiary)
                }
                Text(mod.description)
                    .font(MCTheme.Font.caption(12))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            PillBadge(text: mod.category, color: MCTheme.Palette.info)

            Text(mod.author)
                .font(MCTheme.Font.caption(11))
                .foregroundStyle(MCTheme.Palette.textTertiary)
                .frame(width: 80, alignment: .trailing)

            Toggle("", isOn: Binding(
                get: { mod.isEnabled },
                set: { _ in onToggle(mod.id) }
            ))
            .toggleStyle(.switch)
            .tint(MCTheme.Palette.accent)
            .labelsHidden()
            .controlSize(.small)
        }
        .padding(MCTheme.Space.lg)
        .background(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .fill(hovering ? MCTheme.Palette.surface : MCTheme.Palette.surfaceRaised)
                .shadow(color: hovering ? MCTheme.Palette.shadowSoft : .clear, radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
        )
        .opacity(mod.isEnabled ? 1 : 0.6)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { self.hovering = hovering }
        }
    }
}
