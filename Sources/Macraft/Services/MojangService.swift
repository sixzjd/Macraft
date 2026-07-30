import Foundation
import Observation

// MARK: - Mojang Service
/// 负责从 BMCLAPI 镜像 / Mojang 官方拉取 Minecraft 版本清单
@Observable
final class MojangService {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    /// 下载源（参考 PCL 的下载源配置）
    enum DownloadSource: Int, CaseIterable {
        case bmclapi = 0   // BMCLAPI 镜像（推荐）
        case official = 1  // Mojang 官方
        case mcbbs = 2     // MCBBS 镜像

        var manifestURL: URL {
            switch self {
            case .bmclapi:
                return URL(string: "https://bmclapi2.bangbang93.com/mc/game/version_manifest_v2.json")!
            case .official:
                return URL(string: "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json")!
            case .mcbbs:
                return URL(string: "https://download.mcbbs.net/mc/game/version_manifest_v2.json")!
            }
        }

        var name: String {
            switch self {
            case .bmclapi: return "BMCLAPI"
            case .official: return "官方源"
            case .mcbbs: return "MCBBS"
            }
        }
    }

    var downloadSource: DownloadSource = .bmclapi
    var state: LoadState = .idle
    var allVersions: [MCVersion] = []
    var latestRelease: String = ""
    var latestSnapshot: String = ""

    var releaseCount: Int { allVersions.filter { $0.type == .release }.count }
    var snapshotCount: Int { allVersions.filter { $0.type == .snapshot }.count }

    @MainActor
    func loadManifest() async {
        state = .loading
        // 尝试多个源：当前选择 → 官方源
        let fallbackURL = URL(string: "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json")!
        let urls: [URL] = downloadSource.manifestURL == fallbackURL
            ? [fallbackURL]
            : [downloadSource.manifestURL, fallbackURL]

        var lastError: Error?
        for url in urls {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), !data.isEmpty else {
                    continue
                }
                let manifest = try JSONDecoder().decode(VersionManifest.self, from: data)
                self.allVersions = manifest.versions
                self.latestRelease = manifest.latest.release
                self.latestSnapshot = manifest.latest.snapshot
                self.state = .loaded
                return
            } catch {
                lastError = error
                continue
            }
        }
        self.state = .failed(lastError?.localizedDescription ?? "所有下载源均无法连接")
    }

    /// 按搜索词与类型过滤
    func filteredVersions(search: String, showReleases: Bool, showSnapshots: Bool,
                          showOld: Bool) -> [MCVersion] {
        allVersions.filter { v in
            let typeOK: Bool
            switch v.type {
            case .release:  typeOK = showReleases
            case .snapshot: typeOK = showSnapshots
            default:        typeOK = showOld
            }
            guard typeOK else { return false }
            guard !search.isEmpty else { return true }
            return v.id.localizedCaseInsensitiveContains(search)
        }
    }
}
