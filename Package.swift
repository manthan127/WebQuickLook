// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebQuickLook",
    // using iOS 15 because diving delegate to individual task is only available after iOs 15
    // can support previous version if we use delegate in the settion object
    platforms: [.iOS(.v15)], 
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WebQuickLook",
            targets: ["WebQuickLook"]),
    ],
    dependencies: [
//        .package(name: "RemoteResourceKit", path: "../RemoteResourceKit")
        .package(url: "https://github.com/manthan127/RemoteResourceKit.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WebQuickLook",
            dependencies: ["RemoteResourceKit"]
        ),
        .testTarget(
            name: "WebQuickLookTests",
            dependencies: ["WebQuickLook"]),
    ]
)
