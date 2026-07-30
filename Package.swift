// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Macraft",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Macraft",
            path: "Sources/Macraft"
        )
    ]
)
