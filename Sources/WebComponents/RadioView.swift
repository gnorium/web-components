#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A radio input with label and optional description that supports single selection from a group.
public struct RadioView: HTMLProtocol {
	let id: String
	let name: String
	let value: String
	let checked: Bool
	let inline: Bool
	let disabled: Bool
	let hideLabel: Bool
	let status: ValidationStatus
	let labelContent: [HTMLProtocol]
	let descriptionContent: [HTMLProtocol]
	let customInputContent: [HTMLProtocol]
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
		hideLabel: Bool = false,
		status: ValidationStatus = .default,
		class: String = "",
		@HTMLBuilder label: () -> [HTMLProtocol],
		@HTMLBuilder description: () -> [HTMLProtocol] = { [] },
		@HTMLBuilder customInput: () -> [HTMLProtocol] = { [] }
	) {
		self.id = id
		self.name = name
		self.value = value
		self.hideLabel = hideLabel
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
	private func radioViewCSS(_ inline: Bool) -> [CSSProtocol] {
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
	private func radioInputCSS(_ disabled: Bool, _ status: ValidationStatus) -> [CSSProtocol] {
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
				boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
			}
		}

		pseudoClass(.hover, not(.disabled)) {
			nextSibling(".radio-icon") {
				borderColor(borderColorInputBinaryHover).important()
			}
		}
	}

	@CSSBuilder
	private func radioIconCSS(_ disabled: Bool, _ status: ValidationStatus) -> [CSSProtocol] {
		display(.inlineBlock)
		position(.relative)
		width(minSizeInputBinary)
		height(minSizeInputBinary)
		flexShrink(0)
		backgroundColor(disabled ? backgroundColorDisabled : backgroundColorBase)
		border(borderWidthBase, .solid, status == .error ? borderColorRed : (disabled ? borderColorDisabled : borderColorInputBinary))
		borderRadius(borderRadiusCircle)
		transition(.all, transitionDurationBase, transitionTimingFunctionSystem)
		cursor(disabled ? cursorBaseDisabled : cursorBaseHover)
	}

	@CSSBuilder
	private func radioLabelWrapperCSS(_ disabled: Bool) -> [CSSProtocol] {
		display(.flex)
		flexDirection(.column)
		gap(spacing4)
		cursor(disabled ? cursorBaseDisabled : cursorBaseHover)
		userSelect(.none)
	}

	@CSSBuilder
	private func radioLabelTextCSS(_ disabled: Bool) -> [CSSProtocol] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightSmall22)
		fontWeight(fontWeightNormal)
		color(disabled ? colorDisabled : colorBase)
	}

	@CSSBuilder
	private func radioDescriptionCSS(_ disabled: Bool) -> [CSSProtocol] {
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(disabled ? colorDisabled : colorSubtle)
	}

	@CSSBuilder
	private func visuallyHiddenCSS() -> [CSSProtocol] {
		position(.absolute)
		width(px(1))
		height(px(1))
		margin(px(-1))
		padding(0)
		overflow(.hidden)
		clip(rect(0, 0, 0, 0))
		whiteSpace(.nowrap)
		borderWidth(0)
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
							if hideLabel {
								visuallyHiddenCSS()
							}
						}
				}
				.for(id)
				.class("radio-label")
				.style {
					if hideLabel {
						visuallyHiddenCSS()
					}
				}

				if hasDescription && !hideLabel {
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
				if hideLabel {
					visuallyHiddenCSS()
				}
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
