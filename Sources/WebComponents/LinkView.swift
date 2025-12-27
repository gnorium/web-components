#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Link component following Wikimedia Codex design system specification
/// Navigates the user to another page, view or section.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/mixins/link.html
public struct LinkView: HTML {
	let url: String
	let underlined: Bool
	let redLink: Bool
	let external: Bool
	let content: [HTML]
	let `class`: String

	public init(
		url: String,
		underlined: Bool = false,
		redLink: Bool = false,
		external: Bool = false,
		class: String = "",
		@HTMLBuilder content: () -> [HTML]
	) {
		self.url = url
		self.underlined = underlined
		self.redLink = redLink
		self.external = external
		self.content = content()
		self.`class` = `class`
	}

	@CSSBuilder
	private func linkViewCSS(_ underlined: Bool, _ redLink: Bool) -> [CSS] {
		if redLink {
			color(colorDestructive)
		} else {
			color(colorProgressive)
		}

		if underlined {
			textDecoration(.underline)
		}
		else {
			textDecoration(.none)
		}
		cursor(cursorBaseHover)

		pseudoClass(.hover) {
			if redLink {
				color(colorDestructiveHover).important()
			} else {
				color(colorProgressiveHover).important()
			}
			textDecoration(.underline).important()
		}

		pseudoClass(.active) {
			if redLink {
				color(colorDestructiveActive).important()
			} else {
				color(colorProgressiveActive).important()
			}
		}

		pseudoClass(.focus) {
			outline(borderWidthThick, .solid, borderColorProgressive).important()
			outlineOffset(px(1)).important()
			borderRadius(borderRadiusBase).important()
		}

		if !redLink {
			pseudoClass(.visited) {
				color(colorVisited).important()
			}
		}
	}

	@CSSBuilder
	private func linkExternalIconCSS() -> [CSS] {
		display(.inlineBlock)
		width(sizeIconXSmall)
		height(sizeIconXSmall)
		marginLeft(spacing4)
		verticalAlign(.middle)
		fontSize(sizeIconXSmall)
	}

	public func render(indent: Int = 0) -> String {
		let linkClasses = {
			var classes = "link-view"
			if underlined {
				classes += " link-underlined"
			}
			if redLink {
				classes += " link-red"
			}
			if external {
				classes += " link-external"
			}
			if !`class`.isEmpty {
				classes += " \(`class`)"
			}
			return classes
		}()

		var link = a {
			content

			if external {
				span { "↗" }
				.class("link-external-icon")
				.ariaHidden(true)
				.style {
					linkExternalIconCSS()
				}
			}
		}
		.href(url)
		.class(linkClasses)

		if external {
			link = link
				.target(.blank)
				.rel((.noopener, .noreferrer))
		}

		return link
			.style {
				linkViewCSS(underlined, redLink)
			}
			.render(indent: indent)
	}
}

#endif
