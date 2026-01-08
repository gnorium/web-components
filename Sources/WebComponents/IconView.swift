#if !os(WASI)

import Foundation
import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Icon component following Wikimedia Codex design system specification
/// A graphical representation of an idea. Can be used inside other components.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/icon.html
public struct IconView: HTML {
	let icon: [HTML]
	let iconLabel: String?
	let size: IconSize
	let iconColor: CSSColor?
	let `class`: String

	public enum IconSize: String, Sendable {
		case medium
		case small
		case xSmall = "x-small"
	}

	public init(
		icon: [HTML],
		iconLabel: String? = nil,
		size: IconSize = .medium,
		iconColor: CSSColor? = nil,
		class: String = ""
	) {
		self.icon = icon
		self.iconLabel = iconLabel
		self.size = size
		self.iconColor = iconColor
		self.`class` = `class`
	}

	/// Convenience init for icon components
	public init(
		@HTMLBuilder icon: () -> [HTML],
		iconLabel: String? = nil,
		size: IconSize = .medium,
		iconColor: CSSColor? = nil,
		class: String = ""
	) {
		self.icon = icon()
		self.iconLabel = iconLabel
		self.size = size
		self.iconColor = iconColor
		self.`class` = `class`
	}

	/// Convenience init for icon components with size parameter passed to icon builder
	public init(
		@HTMLBuilder icon: (_ size: Length) -> [HTML],
		iconLabel: String? = nil,
		size: IconSize = .medium,
		iconColor: CSSColor? = nil,
		class: String = ""
	) {
		let actualSize = Self.sizeToLength(size)
		self.icon = icon(actualSize)
		self.iconLabel = iconLabel
		self.size = size
		self.iconColor = iconColor
		self.`class` = `class`
	}

	private static func sizeToLength(_ size: IconSize) -> Length {
		// Return concrete pixel values for SVG attributes (SVG doesn't support CSS variables)
		switch size {
		case .medium:
			return px(20)  // fontSizeMedium16 (16px) + 4px
		case .small:
			return px(16)  // fontSizeSmall14 (14px) + 2px
		case .xSmall:
			return px(12)
		}
	}

	@CSSBuilder
	private func iconViewCSS(_ size: IconSize, _ iconColor: CSSColor?) -> [CSS] {
		display(.block)
		flexShrink(0)

		switch size {
			case .medium:
				width(sizeIconMedium)
				height(sizeIconMedium)
			case .small:
				width(sizeIconSmall)
				height(sizeIconSmall)
			case .xSmall:
				width(sizeIconXSmall)
				height(sizeIconXSmall)
		}

		if let iconColor = iconColor {
			color(iconColor)
		}
	}

	public func render(indent: Int = 0) -> String {
		let iconClasses = {
			var classes = "icon-view"
			classes += " icon-\(size.rawValue)"
			if !`class`.isEmpty {
				classes += " \(`class`)"
			}
			return classes
		}()

		let baseElement = span {
			icon
		}
		.class(iconClasses)
		.ariaHidden(iconLabel == nil)
		.style {
			iconViewCSS(size, iconColor)
		}

		if let iconLabel = iconLabel {
			return baseElement.ariaLabel(iconLabel).render(indent: indent)
		} else {
			return baseElement.render(indent: indent)
		}
	}
}

#endif
