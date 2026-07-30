import Foundation

// MARK: - Version Installer
/// 参考 PCL 的安装逻辑：下载 version.json → client.jar → libraries → assets
@Observable
final class VersionInstaller {

    enum InstallState: Equatable {
        case idle
        case downloading(String)   // 当前步骤描述
        case done
        case failed(String)
    }

    var state: InstallState = .idle
    var progress: Double = 0        // 0.0 ~ 1.0
    var statusText: String = ""

    /// 游戏根目录
    var gameRoot: URL {
        let path = NSString("~/Library/Application Support/macraft").expandingTildeInPath
        return URL(fileURLWithPath: path)
    }

    /// BMCLAPI 镜像基础 URL
    private let bmclapi = "https://bmclapi2.bangbang93.com"

    /// 智能下载：先尝试 BMCLAPI 镜像，失败则回退官方源
    private func smartDownload(from urls: [URL]) async throws -> Data {
        var lastError: Error?
        for url in urls {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), !data.isEmpty {
                    return data
                }
            } catch {
                lastError = error
                continue
            }
        }
        throw lastError ?? InstallError.invalidURL
    }

    /// 将官方 URL 转为 [BMCLAPI镜像, 原始URL] 数组
    private func mirrorURLs(_ original: String) -> [URL] {
        let mirrored = original
            .replacingOccurrences(of: "https://piston-meta.mojang.com", with: bmclapi)
            .replacingOccurrences(of: "https://piston-data.mojang.com", with: bmclapi)
            .replacingOccurrences(of: "https://launchermeta.mojang.com", with: bmclapi)
            .replacingOccurrences(of: "https://launcher.mojang.com", with: bmclapi)
            .replacingOccurrences(of: "https://libraries.minecraft.net", with: "\(bmclapi)/maven")
            .replacingOccurrences(of: "https://resources.download.minecraft.net", with: "\(bmclapi)/assets")
        var urls: [URL] = []
        if mirrored != original, let m = URL(string: mirrored) { urls.append(m) }
        if let o = URL(string: original) { urls.append(o) }
        return urls
    }

    /// 已安装的版本列表
    var installedVersions: [String] {
        let versionsDir = gameRoot.appendingPathComponent("versions")
        guard let dirs = try? FileManager.default.contentsOfDirectory(atPath: versionsDir.path) else { return [] }
        return dirs.filter { d in
            let jsonPath = versionsDir.appendingPathComponent("\(d)/\(d).json")
            return FileManager.default.fileExists(atPath: jsonPath.path)
        }.sorted().reversed()
    }

    /// 检查某版本是否已安装
    func isInstalled(_ version: String) -> Bool {
        let jar = gameRoot.appendingPathComponent("versions/\(version)/\(version).jar")
        let json = gameRoot.appendingPathComponent("versions/\(version)/\(version).json")
        return FileManager.default.fileExists(atPath: jar.path) &&
               FileManager.default.fileExists(atPath: json.path)
    }

    // MARK: - 完整安装流程
    @MainActor
    func install(version: MCVersion) async {
        state = .downloading("准备安装…")
        progress = 0

        do {
            // 1. 下载 version.json
            statusText = "正在下载版本配置文件…"
            progress = 0.05
            let versionJSON = try await downloadVersionJSON(version)

            // 2. 下载 client.jar
            statusText = "正在下载游戏主文件…"
            progress = 0.15
            try await downloadClientJar(versionJSON)

            // 3. 下载 libraries
            statusText = "正在下载运行库…"
            progress = 0.35
            try await downloadLibraries(versionJSON)

            // 4. 下载 assets
            statusText = "正在下载资源文件…"
            progress = 0.7
            try await downloadAssets(versionJSON)

            progress = 1.0
            statusText = "安装完成！"
            state = .done
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Step 1: 下载 version.json
    private func downloadVersionJSON(_ version: MCVersion) async throws -> VersionJSON {
        let urls = mirrorURLs(version.url)
        let data = try await smartDownload(from: urls)
        let versionJSON = try JSONDecoder().decode(VersionJSON.self, from: data)

        // 保存到本地
        let versionDir = gameRoot.appendingPathComponent("versions/\(version.id)")
        try FileManager.default.createDirectory(at: versionDir, withIntermediateDirectories: true)
        let jsonPath = versionDir.appendingPathComponent("\(version.id).json")
        try data.write(to: jsonPath)

        return versionJSON
    }

    // MARK: - Step 2: 下载 client.jar
    private func downloadClientJar(_ versionJSON: VersionJSON) async throws {
        let versionDir = gameRoot.appendingPathComponent("versions/\(versionJSON.id)")
        let jarPath = versionDir.appendingPathComponent("\(versionJSON.id).jar")

        if FileManager.default.fileExists(atPath: jarPath.path) { return }

        guard let clientUrl = versionJSON.downloads?.client?.url else {
            throw InstallError.noClientDownload
        }

        let data = try await smartDownload(from: mirrorURLs(clientUrl))
        try data.write(to: jarPath)
    }

    // MARK: - Step 3: 下载 libraries
    private func downloadLibraries(_ versionJSON: VersionJSON) async throws {
        let libRoot = gameRoot.appendingPathComponent("libraries")
        try FileManager.default.createDirectory(at: libRoot, withIntermediateDirectories: true)

        let nativesDir = gameRoot.appendingPathComponent("versions/\(versionJSON.id)/natives")
        try FileManager.default.createDirectory(at: nativesDir, withIntermediateDirectories: true)

        for lib in versionJSON.libraries {
            guard lib.isActiveOnCurrentOS else { continue }

            if lib.isNative {
                // 下载 native 并解压
                try await downloadAndExtractNative(lib, to: nativesDir)
            } else {
                // 下载普通 library jar
                try await downloadLibrary(lib, to: libRoot)
            }
        }
    }

    private func downloadLibrary(_ lib: Library, to libRoot: URL) async throws {
        // 确定下载 URL 和本地路径
        let localPath: String
        let originalUrl: String

        if let artifact = lib.downloads?.artifact {
            localPath = artifact.path ?? lib.artifactPath
            if let url = artifact.url, !url.isEmpty {
                originalUrl = url
            } else {
                originalUrl = "https://libraries.minecraft.net/\(localPath)"
            }
        } else {
            localPath = lib.artifactPath
            if let customUrl = lib.url {
                originalUrl = "\(customUrl)\(localPath)"
            } else {
                originalUrl = "https://libraries.minecraft.net/\(localPath)"
            }
        }

        guard !localPath.isEmpty else { return }
        let destFile = libRoot.appendingPathComponent(localPath)

        // 已存在则跳过
        if FileManager.default.fileExists(atPath: destFile.path) { return }

        try FileManager.default.createDirectory(
            at: destFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try await smartDownload(from: mirrorURLs(originalUrl))
        try data.write(to: destFile)
    }

    private func downloadAndExtractNative(_ lib: Library, to nativesDir: URL) async throws {
        guard let nativeKey = lib.natives?["osx"] else { return }

        // 从 classifiers 获取 native jar
        let classifierKey = nativeKey.replacingOccurrences(of: "${arch}", with: "64")
        guard let artifact = lib.downloads?.classifiers?[classifierKey] else { return }
        guard let urlStr = artifact.url, !urlStr.isEmpty else { return }

        let data = try await smartDownload(from: mirrorURLs(urlStr))

        // 写入临时文件并解压
        let tempZip = nativesDir.appendingPathComponent("temp_native.zip")
        try data.write(to: tempZip)

        // 使用系统 unzip 解压
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", "-q", tempZip.path, "-d", nativesDir.path]
        try? process.run()
        process.waitUntilExit()

        try? FileManager.default.removeItem(at: tempZip)
    }

    // MARK: - Step 4: 下载 assets
    private func downloadAssets(_ versionJSON: VersionJSON) async throws {
        guard let assetIndex = versionJSON.assetIndex else { return }

        let assetsDir = gameRoot.appendingPathComponent("assets")
        let indexDir = assetsDir.appendingPathComponent("indexes")
        let objectsDir = assetsDir.appendingPathComponent("objects")
        try FileManager.default.createDirectory(at: indexDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: objectsDir, withIntermediateDirectories: true)

        // 下载 asset index json
        let indexPath = indexDir.appendingPathComponent("\(assetIndex.id).json")
        let indexData: Data
        if FileManager.default.fileExists(atPath: indexPath.path) {
            indexData = try Data(contentsOf: indexPath)
        } else {
            let data = try await smartDownload(from: mirrorURLs(assetIndex.url))
            try data.write(to: indexPath)
            indexData = data
        }

        let assetIndexJSON = try JSONDecoder().decode(AssetIndexJSON.self, from: indexData)

        // 下载所有 asset objects（限制并发）
        let totalObjects = assetIndexJSON.objects.count
        var downloaded = 0

        // 分批下载，每批 20 个
        let objects = Array(assetIndexJSON.objects.values)
        let batchSize = 20
        for batchStart in stride(from: 0, to: objects.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, objects.count)
            let batch = Array(objects[batchStart..<batchEnd])

            try await withThrowingTaskGroup(of: Void.self) { group in
                for obj in batch {
                    group.addTask {
                        let hashPrefix = String(obj.hash.prefix(2))
                        let objDir = objectsDir.appendingPathComponent(hashPrefix)
                        let objFile = objDir.appendingPathComponent(obj.hash)

                        if FileManager.default.fileExists(atPath: objFile.path) { return }
                        try FileManager.default.createDirectory(at: objDir, withIntermediateDirectories: true)

                        let officialUrl = "https://resources.download.minecraft.net/\(hashPrefix)/\(obj.hash)"
                        let data = try await self.smartDownload(from: self.mirrorURLs(officialUrl))
                        try data.write(to: objFile)
                    }
                }
                try await group.waitForAll()
            }

            downloaded += batch.count
            let pct = Double(downloaded) / Double(max(totalObjects, 1))
            progress = 0.7 + pct * 0.28
            statusText = "正在下载资源文件… (\(downloaded)/\(totalObjects))"
        }
    }

    enum InstallError: LocalizedError {
        case noClientDownload
        case invalidURL

        var errorDescription: String? {
            switch self {
            case .noClientDownload: return "版本配置中缺少客户端下载链接"
            case .invalidURL: return "无效的下载地址"
            }
        }
    }
}
