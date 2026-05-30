// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "argon2id_ffi",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "argon2id-ffi", type: .static, targets: ["argon2id_ffi"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "argon2id_ffi",
            dependencies: [
                .target(name: "argon2id_ffi_native"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        ),
        .binaryTarget(
            name: "argon2id_ffi_native",
            path: "argon2id_ffi.xcframework"
        )
    ]
)
