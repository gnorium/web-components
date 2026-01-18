#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Checkbox component following Wikimedia Codex design system specification
/// A Checkbox is a binary input that can appear by itself or in a multiselect group.
/// Checkboxes can be selected, unselected or in an indeterminate state.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/checkbox.html
public struct CheckboxView: HTML {
	let id: String
	let name: String
	let value: String
	let checked: Bool
	let disabled: Bool
	let indeterminate: Bool
	let inline: Bool
	let hideLabel: Bool
	let status: ValidationStatus
	let labelContent: [HTML]
	let descriptionContent: [HTML]
	let customInputContent: [HTML]
	let `class`: String

	public enum ValidationStatus: String, Sendable {
		case `default`
		case error
	}

	public init(
		id: String,
		name: String,
		value: String = "1",
		checked: Bool = false,
		disabled: Bool = false,
		indeterminate: Bool = false,
		inline: Bool = false,
		hideLabel: Bool = false,
		status: ValidationStatus = .default,
		class: String = "",
		@HTMLBuilder label: () -> [HTML],
		@HTMLBuilder description: () -> [HTML] = { [] },
		@HTMLBuilder customInput: () -> [HTML] = { [] }
	) {
		self.id = id
		self.name = name
		self.value = value
		self.checked = checked
		self.disabled = disabled
		self.indeterminate = indeterminate
		self.inline = inline
		self.hideLabel = hideLabel
		self.status = status
		self.`class` = `class`
		self.labelContent = label()
		self.descriptionContent = description()
		self.customInputContent = customInput()
	}

	@CSSBuilder
	private func checkboxViewCSS(_ inline: Bool) -> [CSS] {
		if inline {
			display(.inlineFlex)
		} else {
			display(.flex)
		}
		alignItems(.center)
		position(.relative)
		minHeight(minSizeInputBinary)
		gap(spacing8)

		if inline {
			marginRight(spacing16)

			pseudoClass(.lastChild) {
				marginRight(0).important()
			}
		} else {
			marginBottom(spacing8)

			pseudoClass(.lastChild) {
				marginBottom(0).important()
			}
		}
	}

	@CSSBuilder
	private func checkboxIconWrapperCSS() -> [CSS] {
		display(.inlineFlex)
		position(.relative)
		verticalAlign(.middle)
	}

	@CSSBuilder
	private func checkboxInputCSS(_ disabled: Bool) -> [CSS] {
		position(.absolute)
		width(perc(100))
		height(perc(100))
		margin(0)
		opacity(0)
		zIndex(zIndexAboveContent)
		cursor(disabled ? cursorBaseDisabled : .pointer)

		// Checkmark visibility
		pseudoClass(":checked") {
			nextSibling(".checkbox-icon") {
				pseudoElement(.before) {
					opacity(1).important()
				}
			}
		}

		pseudoClass(.indeterminate) {
			nextSibling(".checkbox-icon") {
				pseudoElement(.before) {
					opacity(1).important()
				}
			}
		}

		pseudoClass(.checked) {
			nextSibling(".checkbox-icon") {
				backgroundColor(backgroundColorInputBinaryChecked).important()
				borderColor(borderColorInputBinaryChecked).important()
			}
		}

		pseudoClass(.checked, .disabled) {
			nextSibling(".checkbox-icon") {
				backgroundColor(backgroundColorDisabledSubtle).important()
				borderColor(borderColorDisabled).important()
			}
		}

		pseudoClass(.focus) {
			nextSibling(".checkbox-icon") {
				borderColor(borderColorInputBinaryFocus).important()
				boxShadow(px(0), px(0), px(0), px(1), boxShadowColorProgressiveFocus).important()
			}
		}

		pseudoClass(.enabled, .hover) {
			nextSibling(".checkbox-icon") {
				borderColor(borderColorInputBinaryHover).important()
			}
		}

		pseudoClass(.enabled, .hover, .checked) {
			nextSibling(".checkbox-icon") {
				backgroundColor(backgroundColorInputBinaryChecked).important()
				borderColor(borderColorInputBinaryHover).important()
			}
		}

		pseudoClass(.enabled, .active) {
			nextSibling(".checkbox-icon") {
				backgroundColor(backgroundColorInputBinaryChecked).important()
				borderColor(borderColorInputBinaryActive).important()
			}
		}

		pseudoClass(.enabled, .active, .checked) {
			nextSibling(".checkbox-icon") {
				backgroundColor(backgroundColorInputBinaryChecked).important()
				borderColor(borderColorInputBinaryActive).important()
			}
		}
	}

	@CSSBuilder
	private func checkboxIconCSS(_ status: ValidationStatus, _ disabled: Bool, _ checked: Bool, _ indeterminate: Bool) -> [CSS] {
		display(.inlineBlock)
		position(.relative)
		pointerEvents(.none)
		width(minSizeInputBinary)
		height(minSizeInputBinary)
		if disabled {
			backgroundColor(backgroundColorDisabledSubtle)
		} else {
			backgroundColor(backgroundColorBase)
		}
		if disabled {
			border(borderWidthBase, .solid, borderColorDisabled)
		} else if status == .error {
			border(borderWidthBase, .solid, borderColorError)
		} else {
			border(borderWidthBase, .solid, borderColorInputBinary)
		}
		borderRadius(borderRadiusMinimal)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		flexShrink(0)

		pseudoElement(.before) {
			content("\"\"")
			position(.absolute)
			top(perc(50))
			left(perc(50))
			pointerEvents(.none)
			transition(transitionPropertyFade, transitionDurationBase)
			opacity(0) // Shown when input is checked/indeterminate

			if indeterminate {
				width(px(10))
				height(px(2))
				backgroundColor(colorInvertedFixed)
				transform(translate("-50%", "-50%"))
			} else {
				width(px(5))
				height(px(9))
				borderLeft(px(2), .solid, colorInvertedFixed)
				borderBottom(px(2), .solid, colorInvertedFixed)
				// Fine-tuned visual centering for rotated L shape
				transform(translate("-50%", "-55%"), rotate(deg(-45)))
			}
		}
	}

	@CSSBuilder
	private func checkboxLabelWrapperCSS() -> [CSS] {
		flex(1)
	}

	@CSSBuilder
	private func checkboxCustomInputCSS() -> [CSS] {
		display(.block)
	}

	public func render(indent: Int = 0) -> String {
		let hasDescription = !descriptionContent.isEmpty
		let hasCustomInput = !customInputContent.isEmpty
		let descriptionId = hasDescription ? "\(id)-description" : nil

		return div {
			span {
				input()
				.type(.checkbox)
				.id(id)
				.name(name)
				.value(value)
				.checked(checked)
				.disabled(disabled)
				.ariaDescribedby(descriptionId)
				.class("checkbox-input")
				.style {
					checkboxInputCSS(disabled)
				}

				span()
				.class("checkbox-icon")
				.style {
					checkboxIconCSS(status, disabled, checked, indeterminate)
				}
			}
			.class("checkbox-icon-wrapper")
			.style {
				checkboxIconWrapperCSS()
			}

			div {
				LabelView(
					visuallyHidden: hideLabel,
					inputId: id,
					descriptionId: hasDescription ? descriptionId : nil,
					disabled: disabled
				) {
					labelContent
				} description: {
					if hasDescription {
						descriptionContent
					}
				}

				if hasCustomInput {
					div {
						customInputContent
					}
					.class("checkbox-custom-input")
					.style {
						checkboxCustomInputCSS()
					}
				}
			}
			.class("checkbox-label-wrapper")
			.style {
				checkboxLabelWrapperCSS()
			}
		}
		.class(`class`.isEmpty ? "checkbox-view" : "checkbox-view \(`class`)")
		.style {
			checkboxViewCSS(inline)
		}
		.render(indent: indent)
	}
}

#endif
