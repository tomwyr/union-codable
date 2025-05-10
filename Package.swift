// swift-tools-version: 6.1

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "UnionCodable",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "UnionCodable",
            targets: ["UnionCodable"],
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .macro(
            name: "UnionCodable",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "UnionCodableTests",
            dependencies: ["UnionCodable"],
        ),
    ]
)
