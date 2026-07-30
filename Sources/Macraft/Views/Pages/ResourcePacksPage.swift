import SwiftUI

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

    var body: some View {
        PageContainer(title: "资源包管理", subtitle: "材质包、光影、字体与音效包的管理") {
            VStack(spacing: MCTheme.Space.lg) {
                toolbarRow
                packList
            }
        }
    }

    private var toolbarRow: some View {
        HStack {
            Text("\(packs.count) 个资源包 · \(packs.filter(\.isEnabled).count) 个已启用")
                .font(MCTheme.Font.caption(12))
                .foregroundStyle(MCTheme.Palette.textTertiary)
            Spacer()
            GhostButton(title: "打开文件夹", systemImage: "folder") { }
            PrimaryButton(title: "导入资源包", systemImage: "plus") { }
        }
    }

    private var packList: some View {
        VStack(spacing: MCTheme.Space.sm) {
            ForEach(packs) { pack in
                ResourcePackRow(pack: pack) { id in
                    if let i = packs.firstIndex(where: { $0.id == id }) {
                        packs[i].isEnabled.toggle()
                    }
                }
            }
        }
    }
}

// MARK: - Resource Pack Row
struct ResourcePackRow: View {
    let pack: ResourcePack
    let onToggle: (UUID) -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: MCTheme.Space.lg) {
            Image(systemName: pack.iconSymbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(pack.isEnabled ? MCTheme.Palette.accent : MCTheme.Palette.textTertiary)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                        .fill(pack.isEnabled ? MCTheme.Palette.accentSoft : MCTheme.Palette.surfaceRaised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                        .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MCTheme.Space.sm) {
                    Text(pack.name)
                        .font(MCTheme.Font.headline(14))
                        .foregroundStyle(MCTheme.Palette.textPrimary)
                    if pack.resolution != "—" {
                        PillBadge(text: pack.resolution, color: MCTheme.Palette.textSecondary)
                    }
                }
                Text(pack.description)
                    .font(MCTheme.Font.caption(12))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(pack.author)
                .font(MCTheme.Font.caption(11))
                .foregroundStyle(MCTheme.Palette.textTertiary)

            Toggle("", isOn: Binding(
                get: { pack.isEnabled },
                set: { _ in onToggle(pack.id) }
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
        .opacity(pack.isEnabled ? 1 : 0.6)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { self.hovering = hovering }
        }
    }
}
