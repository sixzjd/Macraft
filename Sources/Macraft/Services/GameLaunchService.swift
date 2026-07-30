import Foundation
import AppKit

// MARK: - Game Launch Service
/// 参考 PCL 的启动逻辑：检测 Java → 检测游戏文件 → 构建参数 → 启动进程
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

    /// 检测系统中的 Java 路径
    func findJava() -> String? {
        // 按优先级检测常见 Java 路径
        let candidates = [
            "/usr/bin/java",
            "/opt/homebrew/bin/java",
            "/usr/local/bin/java",
            "/Library/Java/JavaVirtualMachines/*/Contents/Home/bin/java",
        ]
        let fm = FileManager.default
        for path in candidates {
            if path.contains("*") {
                // glob 匹配
                let base = (path as NSString).deletingLastPathComponent
                let baseDir = (base as NSString).deletingLastPathComponent
                if let dirs = try? fm.contentsOfDirectory(atPath: baseDir) {
                    for d in dirs {
                        let javaPath = "/Library/Java/JavaVirtualMachines/\(d)/Contents/Home/bin/java"
                        if fm.isExecutableFile(atPath: javaPath) { return javaPath }
                    }
                }
            } else {
                if fm.isExecutableFile(atPath: path) { return path }
            }
        }
        // 尝试 which java
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["java"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !result.isEmpty && FileManager.default.isExecutableFile(atPath: result) {
            return result
        }
        return nil
    }

    /// 获取 Java 版本
    func getJavaVersion(javaPath: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: javaPath)
        process.arguments = ["-version"]
        let pipe = Pipe()
        process.standardError = pipe  // java -version 输出到 stderr
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        // 提取版本号
        if let range = output.range(of: "version \"") {
            let after = output[range.upperBound...]
            if let end = after.firstIndex(of: "\"") {
                return String(after[..<end])
            }
        }
        return output.components(separatedBy: .newlines).first ?? "未知"
    }

    /// PCL 风格启动流程
    @MainActor
    func launch(version: String, memoryGB: Double) {
        state = .checkingJava
        statusMessage = "正在检测 Java 运行时…"

        guard let javaPath = findJava() else {
            state = .failed("未找到 Java 运行时。\n请安装 Java 17 或更高版本后重试。\n\n推荐：brew install openjdk@21")
            return
        }

        let javaVer = getJavaVersion(javaPath: javaPath)
        statusMessage = "Java \(javaVer) ✓ 正在检查游戏文件…"
        state = .checkingFiles

        // 检查版本目录
        let versionDir = gameDirectory.appendingPathComponent("versions/\(version)")
        let jarPath = versionDir.appendingPathComponent("\(version).jar")

        if !FileManager.default.fileExists(atPath: jarPath.path) {
            state = .failed("未找到 Minecraft \(version) 的游戏文件。\n请先在「版本管理」中安装该版本。")
            return
        }

        state = .launching
        statusMessage = "正在启动 Minecraft \(version)…"

        // 构建启动命令（参考 PCL 的 ModLaunch.vb）
        let libDir = gameDirectory.appendingPathComponent("libraries")
        let assetsDir = gameDirectory.appendingPathComponent("assets")
        let nativesDir = versionDir.appendingPathComponent("natives")

        var classpath = [jarPath.path]
        // 添加 libraries 下的所有 jar
        if let libs = try? FileManager.default.contentsOfDirectory(atPath: libDir.path) {
            for lib in libs where lib.hasSuffix(".jar") {
                classpath.append(libDir.appendingPathComponent(lib).path)
            }
        }

        let args = [
            "-Xmx\(Int(memoryGB * 1024))m",
            "-Xms\(Int(memoryGB * 512))m",
            "-Djava.library.path=\(nativesDir.path)",
            "-cp", classpath.joined(separator: ":"),
            "net.minecraft.client.main.Main",
            "--version", version,
            "--gameDir", gameDirectory.path,
            "--assetsDir", assetsDir.path,
            "--assetIndex", version,
            "--username", "Player",
            "--uuid", UUID().uuidString.replacingOccurrences(of: "-", with: ""),
            "--accessToken", "0",
            "--userType", "legacy",
            "--versionType", "Macraft",
        ]

        // 启动进程
        let process = Process()
        process.executableURL = URL(fileURLWithPath: javaPath)
        process.arguments = args
        process.currentDirectoryURL = gameDirectory

        do {
            try process.run()
            state = .running
            statusMessage = "Minecraft \(version) 已启动！"
        } catch {
            state = .failed("启动失败：\(error.localizedDescription)")
        }
    }

    /// 确保游戏目录结构存在
    func ensureDirectories() {
        let fm = FileManager.default
        let dirs = ["versions", "libraries", "assets", "mods", "resourcepacks", "saves"]
        for d in dirs {
            let url = gameDirectory.appendingPathComponent(d)
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
