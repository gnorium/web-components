#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A flexible layout wrapper that adapts across different breakpoints and screen sizes.
public struct ContainerView: HTMLProtocol {
	let size: Size
	let content: [HTMLProtocol]
	let `class`: String

	public enum Size: String, Sendable {
		case medium
		case large
		case xLarge = "x-large"
		case full
	}

	public init(
		size: Size = .full,
		class: String = "",
		@HTMLBuilder content: () -> [HTMLProtocol]
	) {
		self.size = size
		self.`class` = `class`
		self.content = content()
	}

	@CSSBuilder
	private func containerViewCSS(_ size: Size) -> [CSSProtocol] {
		width(perc(100))
		marginInline(.auto)
		boxSizing(.borderBox)

		// Fluid padding that scales smoothly with viewport width
		// Formula: clamp(min, preferred, max)
		// - Min: 16px (Apple HIG touch-friendly minimum)
		// - Preferred: 5vw (5% of viewport width - scales naturally)
		// - Max: 64px (prevents excessive padding on ultra-wide displays)
		// This ensures padding always feels proportional to screen size
		paddingInlineStart(clamp(spacing16, vw(5), spacing64))
		paddingInlineEnd(clamp(spacing16, vw(5), spacing64))

		switch size {
			case .medium:
				// 720px: optimal for single-column content (60-75 chars per line)
				maxWidth(px(720))
			case .large:
				// 960px: optimal for two-column layouts and forms
				maxWidth(px(960))
			case .xLarge:
				// 1280px: optimal for multi-column content and dashboards
				maxWidth(px(1280))
			case .full:
				// No max-width constraint for full-bleed layouts
				maxWidth(.none)
		}
	}

	public func render(indent: Int = 0) -> String {
		return div {
			content
		}
		.class(`class`.isEmpty ? "container-view" : "container-view \(`class`)")
		.data("size", size.rawValue)
		.style {
			containerViewCSS(size)
		}
		.render(indent: indent)
	}
}

#endif
