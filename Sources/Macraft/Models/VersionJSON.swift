import Foundation

// MARK: - Minecraft Version JSON (完整解析 PCL 格式)
/// 对应 versions/<id>/<id>.json 的完整结构
struct VersionJSON: Codable {
    let id: String
    let type: String?
    let mainClass: String
    let inheritsFrom: String?
    let arguments: Arguments?
    let minecraftArguments: String?  // 旧版格式 (1.12.2 及以前)
    let libraries: [Library]
    let downloads: Downloads?
    let assetIndex: AssetIndex?
    let assets: String?
    let javaVersion: JavaVersionInfo?

    struct Arguments: Codable {
        let game: [ArgumentValue]?
        let jvm: [ArgumentValue]?
    }

    struct JavaVersionInfo: Codable {
        let majorVersion: Int?
        let component: String?
    }
}

// MARK: - Argument Value (支持字符串和带规则的复合参数)
enum ArgumentValue: Codable {
    case simple(String)
    case complex(RuledArgument)

    struct RuledArgument: Codable {
        let rules: [Rule]
        let value: ArgumentStringOrArray
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .simple(str)
        } else {
            let complex = try container.decode(RuledArgument.self)
            self = .complex(complex)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .simple(let s): try container.encode(s)
        case .complex(let c): try container.encode(c)
        }
    }
}

enum ArgumentStringOrArray: Codable {
    case single(String)
    case multiple([String])

    var values: [String] {
        switch self {
        case .single(let s): return [s]
        case .multiple(let arr): return arr
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .single(str)
        } else {
            self = .multiple(try container.decode([String].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let s): try container.encode(s)
        case .multiple(let arr): try container.encode(arr)
        }
    }
}

// MARK: - Rule (操作系统/功能规则)
struct Rule: Codable {
    let action: String  // "allow" or "disallow"
    let os: OSRule?
    let features: [String: Bool]?

    struct OSRule: Codable {
        let name: String?    // "osx", "windows", "linux"
        let arch: String?
        let version: String?
    }

    /// 判断此规则在当前 macOS 系统上是否通过
    func matchesCurrentOS() -> Bool {
        guard let os = os else { return true }  // 无 os 限制 → 全局规则
        guard let name = os.name else { return true }
        return name == "osx"
    }
}

/// 对一组 rules 求值：默认 disallow，逐条匹配
func evaluateRules(_ rules: [Rule]?) -> Bool {
    guard let rules = rules, !rules.isEmpty else { return true }
    var result = false
    for rule in rules {
        if rule.matchesCurrentOS() {
            result = (rule.action == "allow")
        }
    }
    return result
}

// MARK: - Library
struct Library: Codable {
    let name: String
    let downloads: LibraryDownloads?
    let url: String?         // 自定义 maven 仓库
    let rules: [Rule]?
    let natives: [String: String]?
    let extract: ExtractInfo?

    struct LibraryDownloads: Codable {
        let artifact: Artifact?
        let classifiers: [String: Artifact]?
    }

    struct ExtractInfo: Codable {
        let exclude: [String]?
    }

    /// 是否应该在当前系统加载
    var isActiveOnCurrentOS: Bool {
        evaluateRules(rules)
    }

    /// 是否为 native 库
    var isNative: Bool {
        natives?["osx"] != nil
    }

    /// Maven 坐标解析 → 相对路径
    var artifactPath: String {
        // net.minecraft:launchwrapper:1.12 → net/minecraft/launchwrapper/1.12/launchwrapper-1.12.jar
        let parts = name.split(separator: ":")
        guard parts.count >= 3 else { return "" }
        let group = String(parts[0]).replacingOccurrences(of: ".", with: "/")
        let artifact = String(parts[1])
        let version = String(parts[2])
        let classifier = parts.count > 3 ? "-\(parts[3])" : ""
        return "\(group)/\(artifact)/\(version)/\(artifact)-\(version)\(classifier).jar"
    }
}

// MARK: - Artifact (下载信息)
struct Artifact: Codable {
    let path: String?
    let url: String?
    let sha1: String?
    let size: Int?
}

// MARK: - Downloads
struct Downloads: Codable {
    let client: ClientDownload?
    let server: ClientDownload?

    struct ClientDownload: Codable {
        let url: String
        let sha1: String?
        let size: Int?
    }
}

// MARK: - Asset Index
struct AssetIndex: Codable {
    let id: String
    let url: String
    let sha1: String?
    let size: Int?
    let totalSize: Int?
}

// MARK: - Asset Index JSON (assets/indexes/<id>.json)
struct AssetIndexJSON: Codable {
    let objects: [String: AssetObject]

    struct AssetObject: Codable {
        let hash: String
        let size: Int
    }
}
