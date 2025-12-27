#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// ProgressBar component following Wikimedia Codex design system specification
/// A visual element used to indicate the progress of an action or process.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/progress-bar.html
public struct ProgressBarView: HTML {
	let inline: Bool
	let ariaLabel: String?
	let ariaHidden: Bool
	let disabled: Bool
	let `class`: String

	public init(
		inline: Bool = false,
		ariaLabel: String? = nil,
		ariaHidden: Bool = false,
		disabled: Bool = false,
		class: String = ""
	) {
		self.inline = inline
		self.ariaLabel = ariaLabel
		self.ariaHidden = ariaHidden
		self.disabled = disabled
		self.`class` = `class`
	}

	@CSSBuilder
	private func progressBarViewCSS(_ inline: Bool, _ disabled: Bool) -> [CSS] {
		display(.block)
		position(.relative)
		backgroundColor(backgroundColorProgressiveSubtle)
		borderRadius(borderRadiusPill)
		overflow(.hidden)

		if inline {
			height(px(2))
			minWidth(px(64))
		} else {
			height(px(8))
			minWidth(px(256))
		}

		if disabled {
			opacity(0.5)
		}
	}

	@CSSBuilder
	private func progressBarBarCSS() -> [CSS] {
		position(.absolute)
		top(0)
		left(0)
		width(perc(0))
		height(perc(100))
		backgroundColor(backgroundColorProgressive)
		borderRadius(borderRadiusPill)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		animation("progress-bar-indeterminate", s(2), .linear, .infinite)
	}

	public func render(indent: Int = 0) -> String {
		let progressBarClasses = {
			var classes = "progress-bar-view"
			if inline {
				classes += " progress-bar-inline"
			}
			if disabled {
				classes += " progress-bar-disabled"
			}
			if !`class`.isEmpty {
				classes += " \(`class`)"
			}
			return classes
		}()

		var progressBar = div {
			div {}
				.class("progress-bar-bar")
				.style {
					progressBarBarCSS()
				}
		}
		.class(progressBarClasses)
		.role("progressbar")
		.ariaHidden(ariaHidden)
		.ariaValueMin(0)
		.ariaValueMax(100)

		if let ariaLabel = ariaLabel {
			progressBar = progressBar.ariaLabel(ariaLabel)
		}

		return progressBar
			.style {
				progressBarViewCSS(inline, disabled)
			}
			.render(indent: indent)
	}
}

#endif
