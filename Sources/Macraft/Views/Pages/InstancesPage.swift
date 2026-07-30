import SwiftUI
import AppKit

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
    @State private var showCreateSheet = false
    @State private var launchingInstance: GameInstance?
    @State private var showLaunchAlert = false
    @State private var configInstance: GameInstance?

    var body: some View {
        PageContainer(title: "实例管理", subtitle: "每个实例拥有独立的版本、模组与配置，互不干扰") {
            VStack(spacing: MCTheme.Space.lg) {
                toolbarRow
                instanceGrid
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateInstanceSheet { name, version, loader in
                let icons = ["cube", "leaf", "bolt.horizontal", "puzzlepiece", "star", "flame"]
                instances.append(GameInstance(
                    name: name, version: version, loader: loader,
                    lastPlayed: "从未启动", iconSymbol: icons.randomElement()!
                ))
                showCreateSheet = false
            }
        }
        .sheet(item: $configInstance) { instance in
            InstanceConfigSheet(instance: instance) { updated in
                if let idx = instances.firstIndex(where: { $0.id == updated.id }) {
                    instances[idx] = updated
                }
                configInstance = nil
            }
        }
        .alert("启动游戏", isPresented: $showLaunchAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            if let inst = launchingInstance {
                Text("正在启动 Minecraft \(inst.version)（\(inst.loader)）…\n实例：\(inst.name)")
            }
        }
    }

    private var toolbarRow: some View {
        HStack {
            Text("\(instances.count) 个实例")
                .font(MCTheme.Font.caption(12))
                .foregroundStyle(MCTheme.Palette.textTertiary)
            Spacer()
            PrimaryButton(title: "新建实例", systemImage: "plus") {
                showCreateSheet = true
            }
        }
    }

    private var instanceGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: MCTheme.Space.lg)],
                  spacing: MCTheme.Space.lg) {
            ForEach(instances) { instance in
                InstanceCard(
                    instance: instance,
                    isSelected: selectedInstance == instance.id,
                    onTap: { selectedInstance = instance.id },
                    onLaunch: {
                        launchingInstance = instance
                        showLaunchAlert = true
                    },
                    onConfig: { configInstance = instance }
                )
            }
        }
    }
}

// MARK: - Instance Card
struct InstanceCard: View {
    let instance: GameInstance
    let isSelected: Bool
    let onTap: () -> Void
    let onLaunch: () -> Void
    let onConfig: () -> Void
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
            Button(action: onTap) {
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
            }
            .buttonStyle(.plain)

            HStack(spacing: MCTheme.Space.sm) {
                PillBadge(text: instance.loader, color: loaderColor)
                Spacer()
                Text(instance.lastPlayed)
                    .font(MCTheme.Font.caption(11))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
            }

            Divider().overlay(MCTheme.Palette.border)

            HStack {
                PrimaryButton(title: "启动", systemImage: "play.fill", action: onLaunch)
                Spacer()
                GhostButton(title: "配置", systemImage: "gearshape", action: onConfig)
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

// MARK: - Create Instance Sheet
struct CreateInstanceSheet: View {
    let onCreate: (String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var version = "1.21.4"
    @State private var loader = "Vanilla"

    private let versions = ["1.21.4", "1.21.3", "1.21.1", "1.20.6", "1.20.4", "1.20.1", "1.19.4", "1.18.2", "1.16.5"]
    private let loaders = ["Vanilla", "Fabric", "Forge", "NeoForge"]

    var body: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.xl) {
            Text("新建实例")
                .font(MCTheme.Font.title(18))
                .foregroundStyle(MCTheme.Palette.textPrimary)

            VStack(alignment: .leading, spacing: MCTheme.Space.sm) {
                Text("实例名称")
                    .font(MCTheme.Font.callout(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                TextField("例如：我的新世界", text: $name)
                    .textFieldStyle(.plain)
                    .font(MCTheme.Font.body(14))
                    .padding(MCTheme.Space.md)
                    .background(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                            .fill(MCTheme.Palette.backgroundDeep)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                            .strokeBorder(MCTheme.Palette.borderStrong, lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: MCTheme.Space.sm) {
                Text("游戏版本")
                    .font(MCTheme.Font.callout(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                Picker("", selection: $version) {
                    ForEach(versions, id: \.self) { v in
                        Text("Minecraft \(v)").tag(v)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: MCTheme.Space.sm) {
                Text("模组加载器")
                    .font(MCTheme.Font.callout(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                Picker("", selection: $loader) {
                    ForEach(loaders, id: \.self) { l in
                        Text(l).tag(l)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Spacer()
                GhostButton(title: "取消") { dismiss() }
                PrimaryButton(title: "创建实例", systemImage: "plus") {
                    let n = name.trimmingCharacters(in: .whitespaces)
                    onCreate(n.isEmpty ? "新实例" : n, version, loader)
                }
            }
        }
        .padding(MCTheme.Space.xxl)
        .frame(width: 440)
        .background(MCTheme.Palette.surface)
    }
}

// MARK: - Instance Config Sheet
struct InstanceConfigSheet: View {
    @State var instance: GameInstance
    let onSave: (GameInstance) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.xl) {
            Text("实例配置")
                .font(MCTheme.Font.title(18))
                .foregroundStyle(MCTheme.Palette.textPrimary)

            VStack(alignment: .leading, spacing: MCTheme.Space.sm) {
                Text("实例名称")
                    .font(MCTheme.Font.callout(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                TextField("实例名称", text: $instance.name)
                    .textFieldStyle(.plain)
                    .font(MCTheme.Font.body(14))
                    .padding(MCTheme.Space.md)
                    .background(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                            .fill(MCTheme.Palette.backgroundDeep)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                            .strokeBorder(MCTheme.Palette.borderStrong, lineWidth: 1)
                    )
            }

            HStack(spacing: MCTheme.Space.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("版本")
                        .font(MCTheme.Font.caption(12))
                        .foregroundStyle(MCTheme.Palette.textTertiary)
                    Text(instance.version)
                        .font(MCTheme.Font.mono(13))
                        .foregroundStyle(MCTheme.Palette.textPrimary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("加载器")
                        .font(MCTheme.Font.caption(12))
                        .foregroundStyle(MCTheme.Palette.textTertiary)
                    Text(instance.loader)
                        .font(MCTheme.Font.mono(13))
                        .foregroundStyle(MCTheme.Palette.textPrimary)
                }
                Spacer()
            }

            HStack {
                Spacer()
                GhostButton(title: "取消") { dismiss() }
                PrimaryButton(title: "保存", systemImage: "checkmark") {
                    onSave(instance)
                }
            }
        }
        .padding(MCTheme.Space.xxl)
        .frame(width: 400)
        .background(MCTheme.Palette.surface)
    }
}
