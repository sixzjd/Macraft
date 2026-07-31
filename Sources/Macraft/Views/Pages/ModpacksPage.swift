import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Modpack Model
struct ModpackItem: Identifiable {
    var id: String { name }
    var name: String
    var author: String
    var version: String
    var mcVersion: String
    var modCount: Int
    var downloads: String
    var description: String
    var category: String
    var iconSymbol: String
    var isInstalled: Bool = false
}

// MARK: - Modpack Scanner
/// 扫描已安装的整合包（instances 目录中有 modpack.json 的）
struct ModpackScanner {
    static func scanInstalled() -> [ModpackItem] {
        let fm = FileManager.default
        let instancesPath = NSString("~/Library/Application Support/macraft/instances").expandingTildeInPath
        guard let dirs = try? fm.contentsOfDirectory(atPath: instancesPath) else { return [] }
        var results: [ModpackItem] = []
        for dir in dirs.sorted() {
            let jsonPath = "\(instancesPath)/\(dir)/modpack.json"
            guard let data = fm.contents(atPath: jsonPath),
                  let info = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            results.append(ModpackItem(
                name: info["name"] as? String ?? dir,
                author: "本地安装",
                version: info["version"] as? String ?? "—",
                mcVersion: info["mcVersion"] as? String ?? "—",
                modCount: info["modCount"] as? Int ?? 0,
                downloads: "—",
                description: "已安装到实例「\(dir)」",
                category: "本地",
                iconSymbol: "shippingbox",
                isInstalled: true
            ))
        }
        return results
    }
}

// MARK: - Modpacks Page
struct ModpacksPage: View {
    @State private var modpacks: [ModpackItem] = []
    @State private var search = ""
    @State private var installingPack: ModpackItem?
    @State private var installProgress: Double = 0
    @State private var showInstallProgress = false
    @State private var showImportResult = false
    @State private var importMessage = ""

    /// 预设的在线整合包推荐
    private static let onlinePacks: [ModpackItem] = [
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
        .onAppear { loadModpacks() }
        .alert("导入结果", isPresented: $showImportResult) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
        .sheet(isPresented: $showInstallProgress) {
            InstallProgressSheet(pack: installingPack, progress: installProgress)
        }
    }

    private func loadModpacks() {
        // 已安装的整合包 + 在线推荐
        let installed = ModpackScanner.scanInstalled()
        let online = Self.onlinePacks.filter { o in !installed.contains { $0.name == o.name } }
        modpacks = installed + online
    }

    private var toolbarRow: some View {
        HStack(spacing: MCTheme.Space.md) {
            SearchField(text: $search, placeholder: "搜索整合包…")
                .frame(maxWidth: 280)
            Spacer()
            GhostButton(title: "从文件导入", systemImage: "square.and.arrow.down") {
                importModpack()
            }
        }
    }

    private var modpackGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: MCTheme.Space.lg)],
                  spacing: MCTheme.Space.lg) {
            ForEach(filtered) { pack in
                ModpackCard(pack: pack) {
                    startInstall(pack)
                }
            }
        }
    }

    private func importModpack() {
        let panel = NSOpenPanel()
        panel.title = "选择整合包文件（.zip / .mrpack）"
        panel.allowedContentTypes = [
            UTType.zip,
            UTType(filenameExtension: "mrpack") ?? .data
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            // 读取 manifest.json 获取整合包信息
            var packName = url.deletingPathExtension().lastPathComponent
            var mcVer = "—"
            var modCnt = 0
            // 用 unzip 命令读取 manifest
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = ["-p", url.path, "manifest.json"]
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let manifest = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                packName = manifest["name"] as? String ?? packName
                if let mc = manifest["minecraft"] as? [String: Any] {
                    mcVer = mc["version"] as? String ?? "—"
                }
                if let files = manifest["files"] as? [[String: Any]] {
                    modCnt = files.count
                }
            }

            importMessage = "整合包「\(packName)」已识别。\nMC \(mcVer) | \(modCnt) 个模组\n\n请使用命令行安装：\npython3 scripts/install_modpack.py"
            showImportResult = true
            loadModpacks()
        }
    }

    private func startInstall(_ pack: ModpackItem) {
        installingPack = pack
        installProgress = 0
        showInstallProgress = true
        // 模拟下载进度
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            installProgress += Double.random(in: 0.03...0.12)
            if installProgress >= 1.0 {
                installProgress = 1.0
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showInstallProgress = false
                }
            }
        }
    }
}

// MARK: - Modpack Card
struct ModpackCard: View {
    let pack: ModpackItem
    let onInstall: () -> Void
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
            HStack(spacing: MCTheme.Space.md) {
                Image(systemName: pack.iconSymbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(MCTheme.Palette.accent)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                            .fill(MCTheme.Palette.accentSoft)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.name)
                        .font(MCTheme.Font.headline(14))
                        .foregroundStyle(MCTheme.Palette.textPrimary)
                        .lineLimit(1)
                    Text(pack.author)
                        .font(MCTheme.Font.caption(12))
                        .foregroundStyle(MCTheme.Palette.textTertiary)
                }
                Spacer()
            }

            Text(pack.description)
                .font(MCTheme.Font.caption(12))
                .foregroundStyle(MCTheme.Palette.textSecondary)
                .lineLimit(2)

            HStack(spacing: MCTheme.Space.md) {
                PillBadge(text: "MC \(pack.mcVersion)", color: MCTheme.Palette.accent)
                PillBadge(text: "\(pack.modCount) 模组", color: MCTheme.Palette.textSecondary)
                Spacer()
                Text(pack.downloads)
                    .font(MCTheme.Font.caption(11))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
            }

            Divider().overlay(MCTheme.Palette.border)

            HStack {
                PrimaryButton(title: "安装", systemImage: "arrow.down.circle", action: onInstall)
                Spacer()
                Text("v\(pack.version)")
                    .font(MCTheme.Font.mono(11))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
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

// MARK: - Install Progress Sheet
struct InstallProgressSheet: View {
    let pack: ModpackItem?
    let progress: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: MCTheme.Space.xl) {
            if progress >= 1.0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(MCTheme.Palette.success)
                Text("安装完成！")
                    .font(MCTheme.Font.title(18))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
                Text("整合包已就绪，可在实例管理中启动。")
                    .font(MCTheme.Font.body(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                PrimaryButton(title: "完成", systemImage: "checkmark") { dismiss() }
            } else {
                ProgressView(value: progress)
                    .tint(MCTheme.Palette.accent)
                    .frame(width: 300)
                Text("正在安装「\(pack?.name ?? "")」…")
                    .font(MCTheme.Font.body(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                Text("\(Int(progress * 100))%")
                    .font(MCTheme.Font.mono(14))
                    .foregroundStyle(MCTheme.Palette.accent)
            }
        }
        .padding(MCTheme.Space.xxl)
        .frame(width: 380)
        .background(MCTheme.Palette.surface)
    }
}
