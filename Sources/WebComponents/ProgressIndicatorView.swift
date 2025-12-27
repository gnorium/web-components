#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// ProgressIndicator component following Wikimedia Codex design system specification
/// A visual element used to indicate the ongoing, indefinite progress of an action or process.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/progress-indicator.html
public struct ProgressIndicatorView: HTML {
	let showLabel: Bool
	let ariaHidden: Bool
	let ariaLabel: String?
	let content: [HTML]
	let `class`: String

	public init(
		showLabel: Bool = false,
		ariaHidden: Bool = false,
		ariaLabel: String? = nil,
		class: String = "",
		@HTMLBuilder content: () -> [HTML] = { [] }
	) {
		self.showLabel = showLabel
		self.ariaHidden = ariaHidden
		self.ariaLabel = ariaLabel
		self.content = content()
		self.`class` = `class`
	}

	@CSSBuilder
	private func progressIndicatorViewCSS() -> [CSS] {
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
	private func progressIndicatorSpinnerCSS() -> [CSS] {
		display(.inlineBlock)
		width(sizeIconMedium)
		height(sizeIconMedium)
		borderWidth(borderWidthThick)
		borderStyle(.solid)
		borderColor(borderColorProgressive)
		borderTopColor(borderColorTransparent)
		borderRadius(borderRadiusCircle)
		animation("progress-indicator-spin", s(1), .linear, .infinite)
		flexShrink(0)
	}

	@CSSBuilder
	private func progressIndicatorLabelCSS() -> [CSS] {
		display(.inline)
	}

	public func render(indent: Int = 0) -> String {
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
			.render(indent: indent)
	}
}

#endif
