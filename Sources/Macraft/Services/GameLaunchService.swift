import Foundation
import AppKit

// MARK: - Game Launch Service
/// 参考 PCL 的启动逻辑：检测 Java → 解析 version.json → 构建参数 → 启动进程
@Observable
final class GameLaunchService {

    enum LaunchState: Equatable {
        case idle
        case checkingJava
        case checkingFiles
        case launching
        case running
        case failed(String)
    }

    var state: LaunchState = .idle
    var statusMessage: String = ""

    /// 游戏根目录
    var gameDirectory: URL {
        let path = NSString("~/Library/Application Support/macraft").expandingTildeInPath
        return URL(fileURLWithPath: path)
    }

    /// 已安装版本列表
    var installedVersions: [String] {
        let versionsDir = gameDirectory.appendingPathComponent("versions")
        guard let dirs = try? FileManager.default.contentsOfDirectory(atPath: versionsDir.path) else { return [] }
        return dirs.filter { d in
            let jsonPath = versionsDir.appendingPathComponent("\(d)/\(d).json")
            return FileManager.default.fileExists(atPath: jsonPath.path)
        }.sorted().reversed()
    }

    /// 检测系统中的 Java 路径
    func findJava() -> String? {
        let candidates = [
            "/opt/homebrew/opt/openjdk@21/bin/java",
            "/opt/homebrew/opt/openjdk@17/bin/java",
            "/opt/homebrew/bin/java",
            "/usr/local/bin/java",
            "/usr/bin/java",
        ]
        let fm = FileManager.default
        for path in candidates {
            if fm.isExecutableFile(atPath: path) { return path }
        }
        // 搜索 JavaVirtualMachines
        let jvmDir = "/Library/Java/JavaVirtualMachines"
        if let dirs = try? fm.contentsOfDirectory(atPath: jvmDir) {
            for d in dirs.sorted().reversed() {
                let javaPath = "\(jvmDir)/\(d)/Contents/Home/bin/java"
                if fm.isExecutableFile(atPath: javaPath) { return javaPath }
            }
        }
        // which java
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["java"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !result.isEmpty && fm.isExecutableFile(atPath: result) { return result }
        return nil
    }

    /// 获取 Java 版本号
    func getJavaVersion(javaPath: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: javaPath)
        process.arguments = ["-version"]
        let pipe = Pipe()
        process.standardError = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        if let range = output.range(of: "version \"") {
            let after = output[range.upperBound...]
            if let end = after.firstIndex(of: "\"") {
                return String(after[..<end])
            }
        }
        return output.components(separatedBy: .newlines).first ?? "未知"
    }

    // MARK: - PCL 风格启动流程
    @MainActor
    func launch(version: String, username: String, memoryMB: Int) {
        state = .checkingJava
        statusMessage = "正在检测 Java 运行时…"

        guard let javaPath = findJava() else {
            state = .failed("未找到 Java 运行时。\n请安装 Java 17+：brew install openjdk@21")
            return
        }

        let javaVer = getJavaVersion(javaPath: javaPath)
        statusMessage = "Java \(javaVer) ✓ 正在解析版本配置…"
        state = .checkingFiles

        // 读取 version.json
        let versionDir = gameDirectory.appendingPathComponent("versions/\(version)")
        let jsonPath = versionDir.appendingPathComponent("\(version).json")
        let jarPath = versionDir.appendingPathComponent("\(version).jar")

        guard FileManager.default.fileExists(atPath: jsonPath.path) else {
            state = .failed("未找到 \(version).json。\n请先在「版本管理」中安装该版本。")
            return
        }
        guard FileManager.default.fileExists(atPath: jarPath.path) else {
            state = .failed("未找到 \(version).jar 游戏主文件。\n请先在「版本管理」中安装该版本。")
            return
        }

        // 解析 version.json
        let versionJSON: VersionJSON
        do {
            let data = try Data(contentsOf: jsonPath)
            versionJSON = try JSONDecoder().decode(VersionJSON.self, from: data)
        } catch {
            state = .failed("解析版本配置失败：\(error.localizedDescription)")
            return
        }

        state = .launching
        statusMessage = "正在构建启动参数…"

        // 构建 classpath
        let classpath = buildClasspath(versionJSON: versionJSON, jarPath: jarPath)

        // 构建启动参数
        let args = buildArguments(
            versionJSON: versionJSON,
            version: version,
            username: username,
            memoryMB: memoryMB,
            classpath: classpath
        )

        statusMessage = "正在启动 Minecraft \(version)…"

        // 启动 Java 进程
        let process = Process()
        process.executableURL = URL(fileURLWithPath: javaPath)
        process.arguments = args
        process.currentDirectoryURL = gameDirectory

        // 输出日志
        let outPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = outPipe

        do {
            try process.run()
            state = .running
            statusMessage = "Minecraft \(version) 已启动！"

            // 监控进程退出
            DispatchQueue.global().async { [weak self] in
                process.waitUntilExit()
                DispatchQueue.main.async {
                    if process.terminationStatus != 0 {
                        self?.state = .failed("游戏已退出（代码 \(process.terminationStatus)）")
                    } else {
                        self?.state = .idle
                    }
                }
            }
        } catch {
            state = .failed("启动失败：\(error.localizedDescription)")
        }
    }

    // MARK: - 构建 Classpath（参考 PCL）
    private func buildClasspath(versionJSON: VersionJSON, jarPath: URL) -> String {
        let libRoot = gameDirectory.appendingPathComponent("libraries")
        var entries: [String] = []

        for lib in versionJSON.libraries {
            // 跳过 native 库（它们通过 -Djava.library.path 加载）
            if lib.isNative { continue }
            guard lib.isActiveOnCurrentOS else { continue }

            let relPath: String
            if let artifactPath = lib.downloads?.artifact?.path {
                relPath = artifactPath
            } else {
                relPath = lib.artifactPath
            }
            guard !relPath.isEmpty else { continue }

            let fullPath = libRoot.appendingPathComponent(relPath).path
            if FileManager.default.fileExists(atPath: fullPath) {
                entries.append(fullPath)
            }
        }

        // client.jar 放最后（PCL 的做法）
        entries.append(jarPath.path)
        return entries.joined(separator: ":")
    }

    // MARK: - 构建启动参数（参考 PCL 的 ModLaunch）
    private func buildArguments(
        versionJSON: VersionJSON,
        version: String,
        username: String,
        memoryMB: Int,
        classpath: String
    ) -> [String] {
        let nativesDir = gameDirectory.appendingPathComponent("versions/\(version)/natives")
        let assetsDir = gameDirectory.appendingPathComponent("assets")
        let assetIndexId = versionJSON.assetIndex?.id ?? versionJSON.assets ?? version

        var args: [String] = []

        // JVM 内存参数
        args.append("-Xmx\(memoryMB)m")
        args.append("-Xms\(min(memoryMB, 512))m")

        // JVM 参数（从 version.json 的 arguments.jvm）
        if let jvmArgs = versionJSON.arguments?.jvm {
            for arg in jvmArgs {
                switch arg {
                case .simple(let s):
                    args.append(replaceVariables(s, version: version, username: username,
                                                nativesDir: nativesDir.path, assetsDir: assetsDir.path,
                                                assetIndex: assetIndexId, classpath: classpath))
                case .complex(let ruled):
                    if evaluateRules(ruled.rules) {
                        for v in ruled.value.values {
                            args.append(replaceVariables(v, version: version, username: username,
                                                        nativesDir: nativesDir.path, assetsDir: assetsDir.path,
                                                        assetIndex: assetIndexId, classpath: classpath))
                        }
                    }
                }
            }
        } else {
            // 旧版没有 arguments.jvm，手动添加必要参数
            args.append("-Djava.library.path=\(nativesDir.path)")
            args.append("-cp")
            args.append(classpath)
        }

        // 主类
        args.append(versionJSON.mainClass)

        // 游戏参数
        if let gameArgs = versionJSON.arguments?.game {
            for arg in gameArgs {
                switch arg {
                case .simple(let s):
                    args.append(replaceVariables(s, version: version, username: username,
                                                nativesDir: nativesDir.path, assetsDir: assetsDir.path,
                                                assetIndex: assetIndexId, classpath: classpath))
                case .complex(let ruled):
                    // 跳过需要特殊 feature 的参数（如 demo）
                    if let features = ruled.rules.first?.features, features.keys.contains("is_demo_user") {
                        continue
                    }
                    if evaluateRules(ruled.rules) {
                        for v in ruled.value.values {
                            args.append(replaceVariables(v, version: version, username: username,
                                                        nativesDir: nativesDir.path, assetsDir: assetsDir.path,
                                                        assetIndex: assetIndexId, classpath: classpath))
                        }
                    }
                }
            }
        } else if let mcArgs = versionJSON.minecraftArguments {
            // 旧版格式（1.12.2 及以前）
            let parts = mcArgs.split(separator: " ").map(String.init)
            for part in parts {
                args.append(replaceVariables(part, version: version, username: username,
                                            nativesDir: nativesDir.path, assetsDir: assetsDir.path,
                                            assetIndex: assetIndexId, classpath: classpath))
            }
        }

        return args
    }

    // MARK: - 变量替换（PCL 的 ${xxx} 占位符）
    private func replaceVariables(
        _ input: String,
        version: String,
        username: String,
        nativesDir: String,
        assetsDir: String,
        assetIndex: String,
        classpath: String
    ) -> String {
        var result = input
        let replacements: [String: String] = [
            "${auth_player_name}": username,
            "${version_name}": version,
            "${game_directory}": gameDirectory.path,
            "${assets_root}": assetsDir,
            "${assets_index_name}": assetIndex,
            "${auth_uuid}": UUID().uuidString.replacingOccurrences(of: "-", with: ""),
            "${auth_access_token}": "0",
            "${clientid}": "",
            "${auth_xuid}": "",
            "${user_type}": "legacy",
            "${version_type}": "Macraft",
            "${natives_directory}": nativesDir,
            "${launcher_name}": "Macraft",
            "${launcher_version}": "1.0",
            "${classpath}": classpath,
            "${user_properties}": "{}",
            "${resolution_width}": "1280",
            "${resolution_height}": "720",
            "${library_directory}": gameDirectory.appendingPathComponent("libraries").path,
            "${classpath_separator}": ":",
        ]
        for (key, value) in replacements {
            result = result.replacingOccurrences(of: key, with: value)
        }
        return result
    }

    /// 确保游戏目录结构存在
    func ensureDirectories() {
        let fm = FileManager.default
        let dirs = ["versions", "libraries", "assets", "assets/indexes", "assets/objects",
                    "mods", "resourcepacks", "saves"]
        for d in dirs {
            let url = gameDirectory.appendingPathComponent(d)
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
