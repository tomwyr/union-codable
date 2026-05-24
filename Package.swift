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
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", exact: "0.6.4"),
        // https://github.com/pointfreeco/swift-snapshot-testing/issues/1085
        // Pinned to work around swift-macro-testing build issue:
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.18.9"),
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
                "UnionCodable",
                "UnionCodableMacros",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
            ],
        ),
    ],
)
