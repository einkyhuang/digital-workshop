// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SuperWorkbench",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AssetVaultCore", targets: ["AssetVaultCore"]),
        .executable(name: "SuperWorkbench", targets: ["SuperWorkbench"]),
    ],
    targets: [
        .target(
            name: "AssetVaultCore",
            path: "Sources/AssetVaultCore"
        ),
        .executableTarget(
            name: "SuperWorkbench",
            dependencies: ["AssetVaultCore"],
            path: "Sources/SuperWorkbench"
        ),
        .testTarget(
            name: "AssetVaultCoreTests",
            dependencies: ["AssetVaultCore"],
            path: "Tests/AssetVaultCoreTests"
        ),
    ]
)
