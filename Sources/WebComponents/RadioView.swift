#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Radio component following Wikimedia Codex design system specification
/// A radio input with label and optional description that supports single selection from a group.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/radio.html
public struct RadioView: HTML {
	let id: String
	let name: String
	let value: String
	let checked: Bool
	let inline: Bool
	let disabled: Bool
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
		value: String,
		checked: Bool = false,
		inline: Bool = false,
		disabled: Bool = false,
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
		self.inline = inline
		self.disabled = disabled
		self.status = status
		self.`class` = `class`
		self.labelContent = label()
		self.descriptionContent = description()
		self.customInputContent = customInput()
	}

	@CSSBuilder
	private func radioViewCSS(_ inline: Bool) -> [CSS] {
		if inline {
			display(.inlineFlex)
		} else {
			display(.flex)
		}
		alignItems(.center)
		position(.relative)
		minHeight(minSizeInteractivePointer)
		gap(spacing8)
	}

	@CSSBuilder
	private func radioInputCSS(_ disabled: Bool, _ status: ValidationStatus) -> [CSS] {
		position(.absolute)
		width(minSizeInputBinary)
		height(minSizeInputBinary)
		margin(0)
		opacity(0)
		cursor(disabled ? cursorBaseDisabled : cursorBaseHover)

		pseudoClass(.checked, not(.disabled)) {
			nextSibling(".radio-icon") {
				backgroundColor(backgroundColorInputBinaryChecked).important()
				borderColor(borderColorInputBinaryChecked).important()
				borderWidth(borderWidthInputRadioChecked).important()
			}
		}

		pseudoClass(.focus) {
			nextSibling(".radio-icon") {
				borderColor(borderColorInputBinaryFocus).important()
				boxShadow(px(0), px(0), px(0), px(1), boxShadowColorProgressiveFocus).important()
			}
		}

		pseudoClass(.hover, not(.disabled)) {
			nextSibling(".radio-icon") {
				borderColor(borderColorInputBinaryHover).important()
			}
		}
	}

	@CSSBuilder
	private func radioIconCSS(_ disabled: Bool, _ status: ValidationStatus) -> [CSS] {
		display(.inlineBlock)
		position(.relative)
		width(minSizeInputBinary)
		height(minSizeInputBinary)
		flexShrink(0)
		backgroundColor(disabled ? backgroundColorDisabled : backgroundColorBase)
		border(borderWidthBase, .solid, status == .error ? borderColorError : (disabled ? borderColorDisabled : borderColorInputBinary))
		borderRadius(borderRadiusCircle)
		transition(.all, transitionDurationBase, transitionTimingFunctionSystem)
		cursor(disabled ? cursorBaseDisabled : cursorBaseHover)
	}

	@CSSBuilder
	private func radioLabelWrapperCSS(_ disabled: Bool) -> [CSS] {
		display(.flex)
		flexDirection(.column)
		gap(spacing4)
		cursor(disabled ? cursorBaseDisabled : cursorBaseHover)
		userSelect(.none)
	}

	@CSSBuilder
	private func radioLabelTextCSS(_ disabled: Bool) -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightSmall22)
		fontWeight(fontWeightNormal)
		color(disabled ? colorDisabled : colorBase)
	}

	@CSSBuilder
	private func radioDescriptionCSS(_ disabled: Bool) -> [CSS] {
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(disabled ? colorDisabled : colorSubtle)
	}

	public func render(indent: Int = 0) -> String {
		let hasDescription = !descriptionContent.isEmpty
		let hasCustomInput = !customInputContent.isEmpty
		let descriptionId = hasDescription ? "\(id)-description" : nil

		var radioView = div {
			if hasCustomInput {
				customInputContent
			} else {
				input()
					.type(.radio)
					.id(id)
					.name(name)
					.value(value)
					.checked(checked)
					.disabled(disabled)
					.ariaDescribedby(descriptionId)
					.class("radio-input")
					.style {
						radioInputCSS(disabled, status)
					}
			}

			span {}
				.class("radio-icon")
				.ariaHidden(true)
				.style {
					radioIconCSS(disabled, status)
				}

			div {
				label {
					span { labelContent }
						.class("radio-label-text")
						.style {
							radioLabelTextCSS(disabled)
						}
				}
				.for(id)
				.class("radio-label")

				if hasDescription {
					div { descriptionContent }
						.class("radio-description")
						.id(descriptionId ?? "")
						.style {
							radioDescriptionCSS(disabled)
						}
				}
			}
			.class("radio-label-wrapper")
			.style {
				radioLabelWrapperCSS(disabled)
			}
		}
		.class(`class`.isEmpty ? "radio-view" : "radio-view \(`class`)")

		if status == .error {
			radioView = radioView.data("status", "error")
		}

		return radioView
			.style {
				radioViewCSS(inline)
			}
			.render(indent: indent)
	}
}

#endif
