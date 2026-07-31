import SwiftUI
import AppKit

// MARK: - Instance Model
struct GameInstance: Identifiable {
    var id: String { name }
    var name: String
    var version: String
    var loader: String       // Forge / Fabric / NeoForge / Vanilla
    var lastPlayed: String
    var iconSymbol: String
    var modCount: Int
    var directory: String    // 实例目录路径
}

// MARK: - Instance Scanner
/// 扫描 ~/Library/Application Support/macraft/instances/ 目录获取真实实例
struct InstanceScanner {
    static var instancesDir: URL {
        let path = NSString("~/Library/Application Support/macraft/instances").expandingTildeInPath
        return URL(fileURLWithPath: path)
    }

    static func scan() -> [GameInstance] {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(atPath: instancesDir.path) else { return [] }
        var results: [GameInstance] = []
        for dir in dirs.sorted() {
            let dirPath = instancesDir.appendingPathComponent(dir).path
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: dirPath, isDirectory: &isDir), isDir.boolValue else { continue }

            // 读取 modpack.json（整合包安装的实例）
            let modpackJson = dirPath + "/modpack.json"
            var version = "未知"
            var loader = "Vanilla"
            var modCount = 0
            if let data = fm.contents(atPath: modpackJson),
               let info = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                version = info["mcVersion"] as? String ?? "未知"
                if let forge = info["forge"] as? String, !forge.isEmpty {
                    loader = "Forge"
                }
                modCount = info["modCount"] as? Int ?? 0
            }

            // 统计 mods 文件夹中的模组数
            let modsPath = dirPath + "/mods"
            if let mods = try? fm.contentsOfDirectory(atPath: modsPath) {
                let jarCount = mods.filter { $0.hasSuffix(".jar") }.count
                if jarCount > modCount { modCount = jarCount }
                if modCount > 0 && loader == "Vanilla" { loader = "Forge" }
            }

            let icons = ["shippingbox", "cube", "leaf", "bolt.horizontal", "puzzlepiece", "star"]
            results.append(GameInstance(
                name: dir,
                version: version,
                loader: loader,
                lastPlayed: "—",
                iconSymbol: modCount > 0 ? "shippingbox" : "cube",
                modCount: modCount,
                directory: dirPath
            ))
        }
        return results
    }
}

// MARK: - Instances Page
struct InstancesPage: View {
    @Environment(GameLaunchService.self) private var launchService
    @State private var instances: [GameInstance] = []
    @State private var selectedInstance: GameInstance.ID?
    @State private var showCreateSheet = false
    @State private var launchingInstance: GameInstance?
    @State private var showLaunchSheet = false
    @State private var configInstance: GameInstance?

    var body: some View {
        PageContainer(title: "实例管理", subtitle: "每个实例拥有独立的版本、模组与配置，互不干扰") {
            VStack(spacing: MCTheme.Space.lg) {
                toolbarRow
                if instances.isEmpty {
                    Card {
                        EmptyState(
                            icon: "shippingbox",
                            title: "暂无实例",
                            message: "在「整合包」中导入整合包，或点击「新建实例」创建。"
                        )
                    }
                } else {
                    instanceGrid
                }
            }
        }
        .onAppear { instances = InstanceScanner.scan() }
        .sheet(isPresented: $showCreateSheet) {
            CreateInstanceSheet { name, version, loader in
                // 创建实例目录
                let dir = InstanceScanner.instancesDir.appendingPathComponent(name).path
                try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
                try? FileManager.default.createDirectory(atPath: dir + "/mods", withIntermediateDirectories: true)
                instances = InstanceScanner.scan()
                showCreateSheet = false
            }
        }
        .sheet(item: $configInstance) { instance in
            InstanceConfigSheet(instance: instance) { updated in
                configInstance = nil
            }
        }
        .sheet(isPresented: $showLaunchSheet) {
            if let inst = launchingInstance {
                InstanceLaunchSheet(instance: inst)
            }
        }
    }

    private var toolbarRow: some View {
        HStack {
            Text("\(instances.count) 个实例")
                .font(MCTheme.Font.caption(12))
                .foregroundStyle(MCTheme.Palette.textTertiary)
            Spacer()
            GhostButton(title: "刷新", systemImage: "arrow.clockwise") {
                instances = InstanceScanner.scan()
            }
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
                        showLaunchSheet = true
                    },
                    onConfig: { configInstance = instance },
                    onDelete: {
                        // 删除实例目录
                        try? FileManager.default.removeItem(atPath: instance.directory)
                        instances = InstanceScanner.scan()
                        if selectedInstance == instance.id { selectedInstance = nil }
                    }
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
    let onDelete: () -> Void
    @State private var hovering = false
    @State private var showDeleteConfirm = false

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
                    // 删除按钮
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(MCTheme.Palette.destructive.opacity(hovering ? 0.8 : 0))
                    }
                    .buttonStyle(.plain)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: MCTheme.Space.sm) {
                PillBadge(text: instance.loader, color: loaderColor)
                if instance.modCount > 0 {
                    PillBadge(text: "\(instance.modCount) 模组", color: MCTheme.Palette.textSecondary)
                }
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
        .alert("删除实例", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) { onDelete() }
        } message: {
            Text("确定要删除「\(instance.name)」吗？此操作不可撤销。")
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

// MARK: - Instance Launch Sheet
/// 实例启动：使用 GameLaunchService 启动对应版本
struct InstanceLaunchSheet: View {
    @Environment(GameLaunchService.self) private var launchService
    let instance: GameInstance
    @Environment(\.dismiss) private var dismiss
    @State private var launchError = ""
    @State private var started = false

    /// 确定启动用的版本 ID（Forge 版本优先）
    private var launchVersion: String {
        let fv = forgeVersion
        guard !fv.isEmpty else { return instance.version }
        let forgeId = "\(instance.version)-forge-\(fv)"
        let forgeDir = NSString(string: "~/Library/Application Support/macraft/versions/\(forgeId)").expandingTildeInPath
        if FileManager.default.fileExists(atPath: forgeDir + "/\(forgeId).json") {
            return forgeId
        }
        return instance.version
    }

    private var forgeVersion: String {
        let modpackJson = instance.directory + "/modpack.json"
        if let data = FileManager.default.contents(atPath: modpackJson),
           let info = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let forge = info["forge"] as? String {
            return forge
        }
        return ""
    }

    var body: some View {
        VStack(spacing: MCTheme.Space.xl) {
            if !launchError.isEmpty {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(MCTheme.Palette.warning)
                Text("启动失败")
                    .font(MCTheme.Font.headline(15))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
                Text(launchError)
                    .font(MCTheme.Font.body(12))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                GhostButton(title: "关闭") { dismiss() }
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(MCTheme.Palette.accent)
                Text(launchService.statusMessage.isEmpty ? "正在准备启动…" : launchService.statusMessage)
                    .font(MCTheme.Font.body(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                    .multilineTextAlignment(.center)
                if launchService.state == .running {
                    PrimaryButton(title: "完成", systemImage: "checkmark") { dismiss() }
                } else {
                    GhostButton(title: "取消") { dismiss() }
                }
            }
        }
        .padding(MCTheme.Space.xxl)
        .frame(width: 420, height: 280)
        .background(MCTheme.Palette.surface)
        .onAppear {
            guard !started else { return }
            started = true
            launchService.ensureDirectories()
            let ver = launchVersion
            // 检查版本文件是否存在
            let verDir = NSString(string: "~/Library/Application Support/macraft/versions/\(ver)").expandingTildeInPath
            let jsonPath = verDir + "/\(ver).json"
            guard FileManager.default.fileExists(atPath: jsonPath) else {
                launchError = "未找到版本 \(ver) 的配置文件。\n请先在「版本管理」中安装该版本。"
                return
            }
            launchService.launch(version: ver, username: "Player", memoryMB: 4096, instanceDir: instance.directory)
        }
        .onChange(of: launchService.state) { _, newState in
            if case .failed(let msg) = newState {
                launchError = msg
            }
        }
    }
}
