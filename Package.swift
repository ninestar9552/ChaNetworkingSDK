// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChaNetworkingSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ChaNetworkingSDK",
            targets: ["ChaNetworkingSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ChaNetworkingSDK",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire")
            ]),
        .testTarget(
            name: "ChaNetworkingSDKTests",
            dependencies: ["ChaNetworkingSDK"]
        ),
    ]
)
