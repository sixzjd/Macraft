import Foundation

// MARK: - Mojang Version Manifest models

struct VersionManifest: Codable {
    let latest: Latest
    let versions: [MCVersion]

    struct Latest: Codable {
        let release: String
        let snapshot: String
    }
}

struct MCVersion: Codable, Identifiable, Hashable {
    let id: String
    let type: VersionType
    let url: String
    let time: String
    let releaseTime: String
    let sha1: String?
    let complianceLevel: Int?

    /// 人类可读的发布时间
    var releaseDate: Date? {
        ISO8601DateFormatter.withFractionalSeconds.date(from: releaseTime)
            ?? ISO8601DateFormatter.standard.date(from: releaseTime)
    }

    var formattedDate: String {
        guard let releaseDate else { return releaseTime }
        return Self.dateFormatter.string(from: releaseDate)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

enum VersionType: String, Codable {
    case release
    case snapshot
    case oldBeta = "old_beta"
    case oldAlpha = "old_alpha"

    var displayName: String {
        switch self {
        case .release:   return "正式版"
        case .snapshot:  return "快照"
        case .oldBeta:   return "Beta"
        case .oldAlpha:  return "Alpha"
        }
    }

    var shortTag: String {
        switch self {
        case .release:   return "Release"
        case .snapshot:  return "Snapshot"
        case .oldBeta:   return "Beta"
        case .oldAlpha:  return "Alpha"
        }
    }
}

extension ISO8601DateFormatter {
    static let standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
