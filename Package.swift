// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenTrainingPlanCore",
    platforms: [
        .iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OpenTrainingPlanCore",
            targets: ["OpenTrainingPlanCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "5.1.3")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OpenTrainingPlanCore",
            dependencies: ["Yams"]
        ),
        .testTarget(
            name: "OpenTrainingPlanCoreTests",
            dependencies: ["OpenTrainingPlanCore", "Yams"]
        ),
    ]
)
