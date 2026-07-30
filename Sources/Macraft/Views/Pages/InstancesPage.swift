import SwiftUI

// MARK: - Instance Model
struct GameInstance: Identifiable {
    let id = UUID()
    var name: String
    var version: String
    var loader: String       // Forge / Fabric / NeoForge / Vanilla
    var lastPlayed: String
    var iconSymbol: String
}

// MARK: - Instances Page
struct InstancesPage: View {
    @State private var instances: [GameInstance] = [
        GameInstance(name: "生存存档", version: "1.21.4", loader: "Fabric",
                     lastPlayed: "2 小时前", iconSymbol: "leaf"),
        GameInstance(name: "红石工坊", version: "1.20.4", loader: "Forge",
                     lastPlayed: "昨天", iconSymbol: "bolt.horizontal"),
        GameInstance(name: "纯净原版", version: "1.21.4", loader: "Vanilla",
                     lastPlayed: "3 天前", iconSymbol: "cube"),
        GameInstance(name: "模组整合", version: "1.20.1", loader: "NeoForge",
                     lastPlayed: "上周", iconSymbol: "puzzlepiece"),
    ]
    @State private var selectedInstance: GameInstance.ID?

    var body: some View {
        PageContainer(title: "实例管理", subtitle: "每个实例拥有独立的版本、模组与配置，互不干扰") {
            VStack(spacing: MCTheme.Space.lg) {
                toolbarRow
                instanceGrid
            }
        }
    }

    private var toolbarRow: some View {
        HStack {
            Text("\(instances.count) 个实例")
                .font(MCTheme.Font.caption(12))
                .foregroundStyle(MCTheme.Palette.textTertiary)
            Spacer()
            PrimaryButton(title: "新建实例", systemImage: "plus") { }
        }
    }

    private var instanceGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: MCTheme.Space.lg)],
                  spacing: MCTheme.Space.lg) {
            ForEach(instances) { instance in
                InstanceCard(instance: instance,
                             isSelected: selectedInstance == instance.id) {
                    selectedInstance = instance.id
                }
            }
        }
    }
}

// MARK: - Instance Card
struct InstanceCard: View {
    let instance: GameInstance
    let isSelected: Bool
    let onTap: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
                HStack(spacing: MCTheme.Space.md) {
                    Image(systemName: instance.iconSymbol)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MCTheme.Palette.accent)
                        .frame(width: 42, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                                .fill(MCTheme.Palette.accentSoft)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(instance.name)
                            .font(MCTheme.Font.headline(14))
                            .foregroundStyle(MCTheme.Palette.textPrimary)
                        Text("Minecraft \(instance.version)")
                            .font(MCTheme.Font.caption(12))
                            .foregroundStyle(MCTheme.Palette.textTertiary)
                    }
                    Spacer()
                }

                HStack(spacing: MCTheme.Space.sm) {
                    PillBadge(text: instance.loader,
                              color: loaderColor)
                    Spacer()
                    Text(instance.lastPlayed)
                        .font(MCTheme.Font.caption(11))
                        .foregroundStyle(MCTheme.Palette.textTertiary)
                }

                Divider().overlay(MCTheme.Palette.border)

                HStack {
                    PrimaryButton(title: "启动", systemImage: "play.fill") { }
                    Spacer()
                    GhostButton(title: "配置", systemImage: "gearshape") { }
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
                    .strokeBorder(isSelected ? MCTheme.Palette.accent.opacity(0.5) : MCTheme.Palette.border,
                                  lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { self.hovering = hovering }
        }
    }

    private var loaderColor: Color {
        switch instance.loader {
        case "Forge":    return MCTheme.Palette.warning
        case "Fabric":   return MCTheme.Palette.info
        case "NeoForge": return MCTheme.Palette.destructive
        default:         return MCTheme.Palette.textSecondary
        }
    }
}
