import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Resource Pack Model
struct ResourcePack: Identifiable {
    let id = UUID()
    var name: String
    var author: String
    var resolution: String
    var description: String
    var isEnabled: Bool
    var iconSymbol: String
}

// MARK: - Resource Packs Page
struct ResourcePacksPage: View {
    @State private var packs: [ResourcePack] = [
        ResourcePack(name: "Faithful 32x", author: "Faithful Team", resolution: "32×32",
                     description: "忠实于原版风格的高清材质包", isEnabled: true,
                     iconSymbol: "square.grid.3x3"),
        ResourcePack(name: "Complementary Shaders", author: "EminGT", resolution: "—",
                     description: "高质量光影预设，兼容 Iris", isEnabled: true,
                     iconSymbol: "sun.haze"),
        ResourcePack(name: "Bare Bones", author: "MspaceDev", resolution: "16×16",
                     description: "Mojang 宣传片风格的简洁材质", isEnabled: false,
                     iconSymbol: "paintbrush.pointed"),
        ResourcePack(name: "Patrix 128x", author: "PATRICK", resolution: "128×128",
                     description: "写实风格高清材质包", isEnabled: false,
                     iconSymbol: "photo.stack"),
        ResourcePack(name: "Fresh Animations", author: "FreshLX", resolution: "—",
                     description: "为生物添加全新动画效果", isEnabled: true,
                     iconSymbol: "figure.walk"),
    ]
    @State private var showImportResult = false
    @State private var importMessage = ""

    var body: some View {
        PageContainer(title: "资源包管理", subtitle: "材质包、光影、字体与音效包的管理") {
            VStack(spacing: MCTheme.Space.lg) {
                toolbarRow
                packList
            }
        }
        .alert("导入结果", isPresented: $showImportResult) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
    }

    private var toolbarRow: some View {
        HStack {
            Text("\(packs.count) 个资源包 · \(packs.filter(\.isEnabled).count) 个已启用")
                .font(MCTheme.Font.caption(12))
                .foregroundStyle(MCTheme.Palette.textTertiary)
            Spacer()
            GhostButton(title: "打开文件夹", systemImage: "folder") {
                openResourcePackFolder()
            }
            PrimaryButton(title: "导入资源包", systemImage: "plus") {
                importResourcePack()
            }
        }
    }

    private var packList: some View {
        VStack(spacing: MCTheme.Space.sm) {
            ForEach($packs) { $pack in
                ResourcePackRow(pack: $pack) {
                    packs.removeAll { $0.id == pack.id }
                }
            }
        }
    }

    private func importResourcePack() {
        let panel = NSOpenPanel()
        panel.title = "选择资源包文件（.zip）"
        panel.allowedContentTypes = [UTType.zip, UTType(filenameExtension: "mcpack") ?? .data]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            let urls = panel.urls
            let rpDir = NSString("~/Library/Application Support/macraft/resourcepacks").expandingTildeInPath
            try? FileManager.default.createDirectory(atPath: rpDir, withIntermediateDirectories: true)

            for url in urls {
                // PCL 逻辑：复制资源包到 resourcepacks 目录
                let dest = URL(fileURLWithPath: rpDir).appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.copyItem(at: url, to: dest)

                let fileName = url.deletingPathExtension().lastPathComponent
                packs.append(ResourcePack(
                    name: fileName, author: "本地导入", resolution: "—",
                    description: "已复制到 resourcepacks 文件夹",
                    isEnabled: true, iconSymbol: "square.grid.3x3"
                ))
            }
            importMessage = "成功导入 \(urls.count) 个资源包到 resourcepacks 文件夹。"
            showImportResult = true
        }
    }

    private func openResourcePackFolder() {
        let path = NSString("~/Library/Application Support/macraft/resourcepacks").expandingTildeInPath
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Resource Pack Row
struct ResourcePackRow: View {
    @Binding var pack: ResourcePack
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: MCTheme.Space.lg) {
            Image(systemName: pack.iconSymbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(pack.isEnabled ? MCTheme.Palette.accent : MCTheme.Palette.textTertiary)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .fill(pack.isEnabled ? MCTheme.Palette.accentSoft : MCTheme.Palette.backgroundDeep)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MCTheme.Space.sm) {
                    Text(pack.name)
                        .font(MCTheme.Font.headline(14))
                        .foregroundStyle(MCTheme.Palette.textPrimary)
                    if pack.resolution != "—" {
                        PillBadge(text: pack.resolution, color: MCTheme.Palette.info)
                    }
                }
                Text(pack.description)
                    .font(MCTheme.Font.caption(12))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text(pack.author)
                .font(MCTheme.Font.caption(11))
                .foregroundStyle(MCTheme.Palette.textTertiary)

            Toggle("", isOn: $pack.isEnabled)
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
