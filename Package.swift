// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "web-components",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .library(name: "WebComponents", targets: ["WebComponents"])
    ],
    dependencies: [
        .package(url: "https://github.com/gnorium/design-tokens", branch: "main"),
        .package(url: "https://github.com/gnorium/web-apis", branch: "main"),
        .package(url: "https://github.com/gnorium/web-builders", branch: "main"),
        .package(url: "https://github.com/gnorium/web-types", branch: "main")
    ],
    targets: [
        .target(
            name: "WebComponents",
            dependencies: [
                .product(name: "DesignTokens", package: "design-tokens"),
                .product(name: "WebAPIs", package: "web-apis"),
                .product(name: "HTMLBuilder", package: "web-builders"),
                .product(name: "CSSBuilder", package: "web-builders"),
                .product(name: "WebTypes", package: "web-types")
            ]
        )
    ]
)
