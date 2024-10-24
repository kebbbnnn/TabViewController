// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TabViewController",
    platforms: [ .iOS(.v14) ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TabViewController",
            targets: ["TabViewController"]),
    ],
    dependencies: [
      .package(url: "https://github.com/uias/Tabman.git", from: "3.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TabViewController",
            dependencies: [
                .product(name: "Tabman", package: "Tabman"),
            ]
        ),
    ]
)
