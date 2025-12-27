#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// ChipInput component following Wikimedia Codex design system specification
/// A ChipInput allows users to create chips to filter content or make selections.
/// Chips are editable and can be removed.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/chip-input.html
public struct ChipInputView: HTML {
	public struct Chip : Sendable{
		let id: String
		let value: String
		let icon: String?

		public init(id: String, value: String, icon: String? = nil) {
			self.id = id
			self.value = value
			self.icon = icon
		}
	}

	let id: String
	let name: String
	let chips: [Chip]
	let placeholder: String
	let separateInput: Bool
	let disabled: Bool
	let readonly: Bool
	let status: ValidationStatus
	let `class`: String

	public enum ValidationStatus: String, Sendable {
		case `default`
		case error
	}

	public init(
		id: String,
		name: String,
		chips: [Chip] = [],
		placeholder: String = "",
		separateInput: Bool = false,
		disabled: Bool = false,
		readonly: Bool = false,
		status: ValidationStatus = .default,
		class: String = ""
	) {
		self.id = id
		self.name = name
		self.chips = chips
		self.placeholder = placeholder
		self.separateInput = separateInput
		self.disabled = disabled
		self.readonly = readonly
		self.status = status
		self.`class` = `class`
	}

	@CSSBuilder
	private func chipInputViewCSS(_ disabled: Bool) -> [CSS] {
		if disabled {
			opacity(opacityMedium)
			cursor(cursorBaseDisabled)
		}
	}

	@CSSBuilder
	private func chipCSS() -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		maxWidth(perc(100))
		padding(spacing4, spacing8)
		backgroundColor(backgroundColorInteractiveSubtle)
		border(borderWidthBase, .solid, borderColorSubtle)
		borderRadius(borderRadiusBase)
		fontSize(fontSizeSmall14)
		fontWeight(fontWeightNormal)
		color(colorBase)
		cursor(cursorBase)

		pseudoClass(.hover) {
			backgroundColor(backgroundColorInteractiveSubtleHover).important()
			borderColor(borderColorSubtle).important()
		}

		pseudoClass(.focus) {
			borderColor(borderColorProgressiveFocus).important()
			boxShadow(px(0), px(0), px(0), px(1), boxShadowColorProgressiveFocus).important()
			outline(px(1), .solid, .transparent).important()
		}
	}

	@CSSBuilder
	private func chipIconCSS() -> [CSS] {
		display(.inlineFlex)
	}

	@CSSBuilder
	private func chipButtonCSS(_ disabled: Bool) -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		width(minSizeInteractivePointer)
		height(minSizeInteractivePointer)
		padding(0)
		backgroundColor(.transparent)
		border(.none)
		color(colorSubtle)
		cursor(disabled ? cursorBaseDisabled : cursorBase)
		borderRadius(borderRadiusCircle)

		pseudoClass(.hover) {
			backgroundColor(backgroundColorInteractiveSubtleHover).important()
			color(colorBase).important()
		}

		pseudoClass(.active) {
			backgroundColor(backgroundColorInteractiveSubtleActive).important()
		}

		pseudoClass(.focus) {
			outline(px(2), .solid, borderColorProgressiveFocus).important()
			outlineOffset(px(-2)).important()
		}

		if disabled {
			opacity(opacityMedium)
		}
	}


	@CSSBuilder
	private func chipInputChipsCSS(_ status: ValidationStatus) -> [CSS] {
		display(.flex)
		flexWrap(.wrap)
		gap(spacing8)
		padding(spacing8)
		backgroundColor(backgroundColorBase)
		border(borderWidthBase, .solid, status == .error ? borderColorError : borderColorInputBinary)
		borderRadius(borderRadiusBase)
	}

	@CSSBuilder
	private func chipInputInputWrapperCSS(_ status: ValidationStatus) -> [CSS] {
		display(.flex)
		padding(spacing8)
		backgroundColor(backgroundColorBase)
		border(borderWidthBase, .solid, status == .error ? borderColorError : borderColorInputBinary)
		borderRadius(borderRadiusBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

		pseudoClass(.focusWithin) {
			borderColor(borderColorProgressiveFocus).important()
			boxShadow(px(0), px(0), px(0), px(1), boxShadowColorProgressiveFocus).important()
		}
	}

	@CSSBuilder
	private func chipInputItemsCSS(_ status: ValidationStatus, _ disabled: Bool) -> [CSS] {
		display(.flex)
		flexWrap(.wrap)
		alignItems(.center)
		gap(spacing8)
		padding(spacing8)
		minHeight(minSizeInteractivePointer)
		backgroundColor(disabled ? backgroundColorDisabled : backgroundColorBase)
		border(borderWidthBase, .solid, disabled ? borderColorDisabled : (status == .error ? borderColorError : borderColorInputBinary))
		borderRadius(borderRadiusBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

		pseudoClass(.focusWithin) {
			borderColor(borderColorProgressiveFocus).important()
			boxShadow(px(0), px(0), px(0), px(1), boxShadowColorProgressiveFocus).important()
		}

		if disabled {
			color(colorDisabled)
		}
	}

	public func render(indent: Int = 0) -> String {
		let chipElements: [HTML] = chips.map { chip in
			div {
				if let icon = chip.icon {
					span { icon }
						.class("chip-icon")
						.ariaHidden(true)
						.style {
							chipIconCSS()
						}
				}

				span { chip.value }
					.class("chip-text")

				button {
					span { "×" }
						.ariaHidden(true)
				}
				.type(.button)
				.class("chip-button")
				.ariaLabel("Remove \(chip.value)")
				.data("chip-id", chip.id)
				.style {
					chipButtonCSS(disabled)
				}
			}
			.class("chip")
			.data("chip-id", chip.id)
			.tabindex(0)
			.style {
				chipCSS()
			}
		}

		let containerElement: HTMLDivElement

		if separateInput {
			containerElement = div {
				if !chips.isEmpty {
					div { chipElements }
						.class("chip-input-chips")
						.style {
							chipInputChipsCSS(status)
						}
				}

				div {
					TextInputView(
						id: id,
						name: name,
						placeholder: placeholder,
						type: .text,
						status: status == .error ? .error : .default,
						disabled: disabled,
						readonly: readonly
					)
				}
				.class("chip-input-input-wrapper")
				.style {
					chipInputInputWrapperCSS(status)
				}
			}
		} else {
			containerElement = div {
				chipElements
				TextInputView(
					id: id,
					name: name,
					placeholder: placeholder,
					type: .text,
					status: status == .error ? .error : .default,
					disabled: disabled,
					readonly: readonly,
					class: "chip-input-input"
				)
			}
			.class("chip-input-items")
			.style {
				chipInputItemsCSS(status, disabled)
			}
		}

		return div {
			containerElement
		}
		.class(`class`.isEmpty ? "chip-input-view" : "chip-input-view \(`class`)")
		.style {
			chipInputViewCSS(disabled)
		}
		.render(indent: indent)
	}
}

#endif
