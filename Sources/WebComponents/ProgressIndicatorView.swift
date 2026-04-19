#if SERVER

import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import Foundation
import HTMLBuilder
import WebTypes

/// A visual element used to indicate the ongoing, indefinite progress of an action or process.
public struct ProgressIndicatorView: HTMLContent {
	let showLabel: Bool
	let ariaHidden: Bool
	let ariaLabel: String?
	let content: [DOMNode]
	let `class`: String

	public init(
		showLabel: Bool = false,
		ariaHidden: Bool = false,
		ariaLabel: String? = nil,
		class: String = "",
		@HTMLBuilder content: () -> [DOMNode] = { [] }
	) {
		self.showLabel = showLabel
		self.ariaHidden = ariaHidden
		self.ariaLabel = ariaLabel
		self.content = content()
		self.`class` = `class`
	}

	@CSSBuilder
	private func progressIndicatorViewCSS() -> [CSSRule] {
		display(.inlineFlex)
		alignItems(.center)
		gap(spacing8)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightNormal)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
	}

	@CSSBuilder
	private func progressIndicatorSpinnerCSS() -> [CSSRule] {
		display(.inlineBlock)
		width(sizeIconMedium)
		height(sizeIconMedium)
		borderWidth(borderWidthThick)
		borderStyle(.solid)
		borderColor(borderColorBlue)
		borderTopColor(borderColorTransparent)
		borderRadius(borderRadiusCircle)
		animation("progress-indicator-spin", s(1), .linear, .infinite)
		flexShrink(0)
	}

	@CSSBuilder
	private func progressIndicatorLabelCSS() -> [CSSRule] {
		display(.inline)
	}

	public func render() -> DOMNode {
		let hasContent = !content.isEmpty

		var progressIndicator = div {
			span {}
				.class("progress-indicator-spinner")
				.style {
					progressIndicatorSpinnerCSS()
				}

			if hasContent && showLabel {
				span {
					content
				}
				.class("progress-indicator-label")
				.style {
					progressIndicatorLabelCSS()
				}
			}
		}
		.class(`class`.isEmpty ? "progress-indicator-view" : "progress-indicator-view \(`class`)")
		.role("progressbar")
		.ariaHidden(ariaHidden)
		.ariaValueMin(0)
		.ariaValueMax(100)

		// Conditionally apply ariaLabel
		let labelValue = hasContent && !showLabel ? (ariaLabel ?? "Loading") : ariaLabel
		if let labelValue = labelValue {
			progressIndicator = progressIndicator.ariaLabel(labelValue)
		}

		return progressIndicator
			.style {
				progressIndicatorViewCSS()
			}
			.render()
	}
}

#endif
