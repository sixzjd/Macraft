import Foundation
import Observation

// MARK: - Mojang Service
/// 负责从 Mojang 官方拉取 Minecraft 版本清单
@Observable
final class MojangService {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private static let manifestURL =
        URL(string: "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json")!

    var state: LoadState = .idle
    var allVersions: [MCVersion] = []
    var latestRelease: String = ""
    var latestSnapshot: String = ""

    var releaseCount: Int { allVersions.filter { $0.type == .release }.count }
    var snapshotCount: Int { allVersions.filter { $0.type == .snapshot }.count }

    @MainActor
    func loadManifest() async {
        state = .loading
        do {
            let (data, response) = try await URLSession.shared.data(from: Self.manifestURL)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                state = .failed("服务器返回了异常状态码")
                return
            }
            let manifest = try JSONDecoder().decode(VersionManifest.self, from: data)
            self.allVersions = manifest.versions
            self.latestRelease = manifest.latest.release
            self.latestSnapshot = manifest.latest.snapshot
            self.state = .loaded
        } catch {
            self.state = .failed(error.localizedDescription)
        }
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
