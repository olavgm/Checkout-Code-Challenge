// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CheckoutFlow",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "CheckoutFlow", targets: ["CheckoutFlow"])
    ],
    targets: [
        .target(
            name: "CheckoutFlow",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "CheckoutFlowTests",
            dependencies: ["CheckoutFlow"]
        )
    ]
)
