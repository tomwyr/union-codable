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
        .package(url: "https://github.com/apple/swift-syntax.git", from: "601.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", exact: "0.6.2"),
    ],
    targets: [
        .macro(
            name: "UnionCodableMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
        ),
        .target(
            name: "UnionCodable",
            dependencies: ["UnionCodableMacros"],
        ),
        .testTarget(
            name: "UnionCodableTests",
            dependencies: [
                "UnionCodableMacros",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
            ],
        ),
    ]
)
