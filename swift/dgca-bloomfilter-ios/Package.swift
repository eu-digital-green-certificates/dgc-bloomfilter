// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "DGCBloomFilter",
    platforms: [.iOS(.v12), .macOS(.v10_14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DGCBloomFilter",
            targets: ["DGCBloomFilter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/leif-ibsen/BigInt", from: "1.2.6"),
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DGCBloomFilter",
            dependencies: ["BigInt"]),
        .testTarget(
            name: "DGCBloomFilterTests",
            dependencies: ["DGCBloomFilter"],
            resources: [
                .process("resources/filter-test.json")
            ]),
    ]
)
