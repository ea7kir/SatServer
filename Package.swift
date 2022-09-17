// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SatServer",
    platforms: [.macOS(.v12)], // seems odd for Linux, but it allows concurrency
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
//         .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0"),
        // using this fork to get 16 bit I2C working
            .package( url: "https://github.com/curuvar/SwiftyGPIO.git", branch: "Safe-I2C" ),
//        .package( url: "https://github.com/curuvar/SwiftyGPIO.git"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SatServer",
            dependencies: [.product(name: "NIOCore", package: "swift-nio"),
                           .product(name: "NIOPosix", package: "swift-nio"),
                           .product(name: "NIOFoundationCompat", package: "swift-nio"),
                           "SwiftyGPIO",
                           "Yams",
            ]),
    ]
)
