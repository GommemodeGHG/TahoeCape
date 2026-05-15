// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TahoeCape",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TahoeCape", targets: ["TahoeCape"])
    ],
    targets: [
        .executableTarget(
            name: "TahoeCape",
            path: "Sources/TahoeCape"
        )
    ]
)
