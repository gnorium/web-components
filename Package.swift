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
    .package(url: "https://github.com/gnorium/diff-engine", branch: "main"),
    .package(url: "https://github.com/gnorium/web-apis", branch: "main"),
    .package(url: "https://github.com/gnorium/web-builders", branch: "main"),
    .package(url: "https://github.com/gnorium/web-types", branch: "main"),
    .package(url: "https://github.com/gnorium/embedded-swift-utilities", branch: "main"),
    .package(url: "https://github.com/gnorium/markdown-utilities", branch: "main"),
  ],
  targets: [
    .executableTarget(
      name: "StyleSheetEmitter",
      dependencies: [
        "WebComponents",
        .product(name: "CSSBuilder", package: "web-builders"),
      ],
      path: "Sources/Executables/StyleSheetEmitter",
      swiftSettings: [
        .define("SERVER", .when(platforms: [.macOS, .linux, .windows]))
      ]
    ),
    .target(
      name: "WebComponents",
      dependencies: [
        .product(name: "CSSBuilder", package: "web-builders"),
        .product(name: "CSSOMBuilder", package: "web-builders"),
        .product(name: "DesignTokens", package: "design-tokens"),
        .product(name: "DiffEngine", package: "diff-engine"),
        .product(name: "DOMBuilder", package: "web-builders"),
        .product(name: "EmbeddedSwiftUtilities", package: "embedded-swift-utilities"),
        .product(name: "HTMLBuilder", package: "web-builders"),
        .product(
          name: "MarkdownUtilities", package: "markdown-utilities",
          condition: .when(platforms: [.macOS, .linux, .windows])),
        .product(name: "SVGBuilder", package: "web-builders"),
        .product(name: "WebAPIs", package: "web-apis"),
        .product(name: "WebTypes", package: "web-types"),
      ],
      swiftSettings: [
        .enableExperimentalFeature("Embedded", .when(platforms: [.wasi])),
        .define("CLIENT", .when(platforms: [.wasi])),
        .define("SERVER", .when(platforms: [.macOS, .linux, .windows])),
      ]
    )
  ]
)
