// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TTYBar",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "TTYBarCore"),
        .executableTarget(name: "TTYBar", dependencies: ["TTYBarCore"]),
        .testTarget(name: "TTYBarCoreTests", dependencies: ["TTYBarCore"]),
    ]
)
