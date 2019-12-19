// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Prelude",
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    products: [
        .library(
            name: "Prelude",
            targets: ["Prelude"]
        )
    ],
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    dependencies: [
    ],
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    targets: [
        .target(
            name: "Prelude",
            dependencies: []
        ),
        .testTarget(
            name: "PreludeTests",
            dependencies: ["Prelude"]
        )
    ]
)
