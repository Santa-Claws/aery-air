// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AeryAir",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AeryAir", targets: ["AeryAir"])
    ],
    targets: [
        .target(name: "AeryCore"),
        .executableTarget(name: "AeryAir", dependencies: ["AeryCore"]),
        .testTarget(name: "AeryCoreTests", dependencies: ["AeryCore"])
    ]
)
