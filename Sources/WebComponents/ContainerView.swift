#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Container component following Wikimedia Codex design system specification
/// A flexible layout wrapper that adapts across different breakpoints and screen sizes.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/container.html
public struct ContainerView: HTML {
	let size: Size
	let content: [HTML]
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
		@HTMLBuilder content: () -> [HTML]
	) {
		self.size = size
		self.`class` = `class`
		self.content = content()
	}

	@CSSBuilder
	private func containerViewCSS(_ size: Size) -> [CSS] {
		width(perc(100))
		marginLeft(.auto)
		marginRight(.auto)
		boxSizing(.borderBox)
        padding(0, rem(1.5))

		switch size {
            case .medium:
                maxWidth(px(720))
            case .large:
                maxWidth(px(960))
            case .xLarge:
                maxWidth(px(1280))
            case .full:
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
