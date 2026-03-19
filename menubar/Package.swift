// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TamaclaudechiMenuBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TamaclaudechiMenuBar", targets: ["TamaclaudechiMenuBar"])
    ],
    targets: [
        .executableTarget(
            name: "TamaclaudechiMenuBar",
            path: "Sources"
        )
    ]
)
