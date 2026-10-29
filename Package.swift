// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KidPlayPad",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "KidPlayPad", targets: ["KidPlayPad"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "KidPlayPad",
            path: "Sources"
        )
    ]
)
