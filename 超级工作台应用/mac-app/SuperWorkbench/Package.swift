// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SuperWorkbench",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SuperWorkbench", targets: ["SuperWorkbench"])
    ],
    targets: [
        .executableTarget(
            name: "SuperWorkbench",
            path: "Sources/SuperWorkbench"
        )
    ]
)
