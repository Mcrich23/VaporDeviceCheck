// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "VaporDeviceCheck",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "VaporDeviceCheck",
            targets: ["VaporDeviceCheck"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.14.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "VaporDeviceCheck",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt")
            ]
        ),
        .testTarget(
            name: "VaporDeviceCheckTests",
            dependencies: [
                .target(name: "VaporDeviceCheck"),
                .product(name: "XCTVapor", package: "vapor")
            ]
        ),
    ]
)
