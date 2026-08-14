// swift-tools-version: 6.1
// This is a Skip (https://skip.dev) package.
import PackageDescription

let package = Package(
    name: "RestFitApp",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "RestFit", type: .dynamic, targets: ["RestFit"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.9.5"),
        .package(url: "https://source.skip.tools/skip-ui.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-firebase.git", "0.4.0"..<"2.0.0")
    ],
    targets: [
        .target(name: "RestFit", dependencies: [
            .product(name: "SkipUI", package: "skip-ui"),
            .product(name: "SkipFirebaseCore", package: "skip-firebase"),
            .product(name: "SkipFirebaseAuth", package: "skip-firebase")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "RestFitTests", dependencies: [
            "RestFit",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
