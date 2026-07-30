import SwiftUI
import AppKit
import UniformTypeIdentifiers

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
    @State private var showImportResult = false
    @State private var importMessage = ""

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
        PageContainer(title: "模组管理", subtitle: "安装、启用或禁用模组，管理加载器依赖") {
            VStack(spacing: MCTheme.Space.lg) {
                toolbarRow
                categoryRow
                modList
            }
        }
        .alert("导入结果", isPresented: $showImportResult) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
    }

    private var toolbarRow: some View {
        HStack(spacing: MCTheme.Space.md) {
            SearchField(text: $search, placeholder: "搜索模组…")
                .frame(maxWidth: 280)
            Spacer()
            GhostButton(title: "打开模组文件夹", systemImage: "folder") {
                openModsFolder()
            }
            PrimaryButton(title: "安装模组", systemImage: "plus") {
                importModFile()
            }
        }
    }

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MCTheme.Space.sm) {
                ForEach(categories, id: \.self) { cat in
                    SelectableChip(label: cat, isSelected: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
        }
    }

    private var modList: some View {
        VStack(spacing: MCTheme.Space.sm) {
            ForEach($mods) { $mod in
                if filtered.contains(where: { $0.id == mod.id }) {
                    ModRow(mod: $mod) {
                        mods.removeAll { $0.id == mod.id }
                    }
                }
            }
            if filtered.isEmpty {
                EmptyState(icon: "puzzlepiece", title: "没有匹配的模组",
                           message: "尝试调整搜索关键词或分类筛选")
                    .padding(.vertical, MCTheme.Space.xxl)
            }
        }
    }

    private func importModFile() {
        let panel = NSOpenPanel()
        panel.title = "选择模组文件（.jar）"
        panel.allowedContentTypes = [UTType(filenameExtension: "jar") ?? .data]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            let urls = panel.urls
            for url in urls {
                let fileName = url.deletingPathExtension().lastPathComponent
                mods.append(ModItem(
                    name: fileName, author: "本地导入", version: "—",
                    description: "从文件导入：\(url.lastPathComponent)",
                    category: "未分类", isEnabled: true, iconSymbol: "puzzlepiece"
                ))
            }
            importMessage = "成功导入 \(urls.count) 个模组文件。"
            showImportResult = true
        }
    }

    private func openModsFolder() {
        let path = NSString("~/Library/Application Support/macraft/mods").expandingTildeInPath
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Mod Row
struct ModRow: View {
    @Binding var mod: ModItem
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: MCTheme.Space.lg) {
            Image(systemName: mod.iconSymbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(mod.isEnabled ? MCTheme.Palette.accent : MCTheme.Palette.textTertiary)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .fill(mod.isEnabled ? MCTheme.Palette.accentSoft : MCTheme.Palette.backgroundDeep)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MCTheme.Space.sm) {
                    Text(mod.name)
                        .font(MCTheme.Font.headline(14))
                        .foregroundStyle(MCTheme.Palette.textPrimary)
                    PillBadge(text: mod.category, color: MCTheme.Palette.textSecondary)
                }
                Text(mod.description)
                    .font(MCTheme.Font.caption(12))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text("v\(mod.version)")
                .font(MCTheme.Font.mono(11))
                .foregroundStyle(MCTheme.Palette.textTertiary)

            Toggle("", isOn: $mod.isEnabled)
                .toggleStyle(.switch)
                .tint(MCTheme.Palette.accent)
                .labelsHidden()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(MCTheme.Palette.destructive.opacity(hovering ? 1 : 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(MCTheme.Space.lg)
        .background(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .fill(MCTheme.Palette.surface)
                .shadow(color: MCTheme.Palette.shadowSoft, radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { self.hovering = hovering }
        }
    }
}
