#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Navigates the user to another page, view or section.
public struct LinkView: HTMLProtocol {
	public enum LinkWeight: String, Sendable {
		case `default`
		case plain
	}

	let url: String
	let underlined: Bool
	let redLink: Bool
	let external: Bool
	let weight: LinkWeight
	let content: [HTMLProtocol]
	let `class`: String

	public init(
		url: String,
		underlined: Bool = false,
		redLink: Bool = false,
		external: Bool = false,
		weight: LinkWeight = .default,
		class: String = "",
		@HTMLBuilder content: () -> [HTMLProtocol]
	) {
		self.url = url
		self.underlined = underlined
		self.redLink = redLink
		self.external = external
		self.weight = weight
		self.content = content()
		self.`class` = `class`
	}

	@CSSBuilder
	private func linkViewCSS(_ underlined: Bool, _ redLink: Bool) -> [CSSProtocol] {
		if redLink {
			color(colorRed)
		} else {
			color(colorBlue)
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
				color(colorRedHover).important()
			} else {
				color(colorBlueHover).important()
			}
			textDecoration(.underline).important()
		}

		pseudoClass(.active) {
			if redLink {
				color(colorRedActive).important()
			} else {
				color(colorBlueActive).important()
			}
		}

		pseudoClass(.focus) {
			outline(borderWidthThick, .solid, borderColorBlue).important()
			outlineOffset(px(1)).important()
			borderRadius(borderRadiusBase).important()
		}

		if redLink {
			pseudoClass(.visited) {
				color(colorRed).important()
			}
		}
	}

	@CSSBuilder
	private func linkViewPlainCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		gap(spacing8)
		height(px(44))
		paddingInline(spacing16)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightNormal)
		color(colorBase)
		textDecoration(.none)
		borderRadius(borderRadiusBase)
		cursor(cursorBaseHover)

		pseudoClass(.focus) {
			outline(borderWidthThick, .solid, borderColorBlue).important()
			outlineOffset(px(1)).important()
			borderRadius(borderRadiusBase).important()
		}
	}

	@CSSBuilder
	private func linkExternalIconCSS() -> [CSSProtocol] {
		display(.inlineBlock)
		width(sizeIconXSmall)
		height(sizeIconXSmall)
		marginInlineStart(spacing4)
		verticalAlign(.middle)
		fontSize(sizeIconXSmall)
	}

	public func render(indent: Int = 0) -> String {
		let linkClasses = {
			var classes = "link-view"
			if weight == .plain {
				classes += " link-plain"
			}
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
				if weight == .plain {
					linkViewPlainCSS()
				} else {
					linkViewCSS(underlined, redLink)
				}
			}
			.render(indent: indent)
	}
}

#endif
