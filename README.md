# WebComponents, as used in [gnorium.com](https://gnorium.com)

Reusable UI components following [Wikimedia Codex](https://doc.wikimedia.org/codex/) design system specification, built with Swift for server-side rendering.

## Overview

WebComponents provides production-ready UI components that follow accessibility guidelines and modern design patterns. Components are design-system agnostic, using configurable design tokens.

## Features

- **Design System**: Components use design tokens from `design-tokens` package
- **Server-Side Rendering**: Pure Swift, no JavaScript required
- **Type Safety**: Compile-time guarantees for component props and styling
- **Accessible**: Built following ARIA guidelines
- **Zero Dependencies on Client**: All components render to clean HTML/CSS

## Components

- **ButtonView**: Interactive buttons with various styles (primary, quiet, destructive)
- **CardView**: Content cards with thumbnails, icons, titles, and descriptions
- **DialogView**: Modal dialogs with headers, footers, and actions
- **DropdownView**: Dropdown menus with items and dividers
- **FieldView**: Form input fields with labels, hints, and validation
- **IconView**: SVG icon components
- **MenuButtonView**: Menu buttons with dropdown panels
- **ProgressBarView**: Determinate and indeterminate progress indicators
- **TextInputView**: Single-line and multi-line text inputs
- **ToggleSwitchView**: Binary toggle switches
- **CheckboxView**: Checkboxes with labels
- **RadioView**: Radio buttons with labels
- And many more...

## Installation

### Swift Package Manager

Add WebComponents to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/gnorium/web-components", branch: "main")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "WebComponents", package: "web-components")
    ]
)
```

## Usage

```swift
import WebComponents
import DesignTokens

// Use components in your views
CardView(
    url: "/articles/swift-web",
    title: { "Building Web Apps with Swift" },
    description: { "A guide to server-side Swift web development" },
    supportingText: { "5 min read" }
)

ButtonView(
    action: .progressive,
    weight: .primary,
    title: { "Get Started" }
)
.onClick("handleClick()")
```

## Requirements

- Swift 6.2+

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details

## Contributing

Contributions welcome! Please open an issue or submit a pull request.

## Related Packages

- [design-tokens](https://github.com/gnorium/design-tokens) - Universal design tokens based on Apple HIG
- [embedded-swift-utilities](https://github.com/gnorium/embedded-swift-utilities) - Utility functions for Embedded Swift environments
- [markdown-utilities](https://github.com/gnorium/markdown-utilities) - Markdown rendering with media attribution support
- [web-administrator](https://github.com/gnorium/web-administrator) - Web administration panel for applications
- [web-apis](https://github.com/gnorium/web-apis) - Web API implementations for Swift WebAssembly
- [web-builders](https://github.com/gnorium/web-builders) - HTML, CSS, JS, and SVG DSL builders
- [web-formats](https://github.com/gnorium/web-formats) - Structured data format builders
- [web-security](https://github.com/gnorium/web-security) - Portable security utilities for web applications
- [web-types](https://github.com/gnorium/web-types) - Shared web types and design tokens
