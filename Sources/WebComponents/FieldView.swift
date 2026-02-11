#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A form field with a label, an input or control, and an optional validation message.
/// Provides features for building accessible form fields to collect user input.
public struct FieldView: HTMLProtocol {
	let id: String
	let labelIcon: String?
	let optional: Bool
	let optionalFlag: String
	let hideLabel: Bool
	let isFieldset: Bool
	let disabled: Bool
	let status: ValidationStatus
	let labelContent: [HTMLProtocol]
	let descriptionContent: [HTMLProtocol]
	let inputContent: [HTMLProtocol]
	let helpTextContent: [HTMLProtocol]
	let messages: ValidationMessages
	let `class`: String
	let labelFontWeight: CSSFontWeight
	let labelFontSize: Length

	public enum ValidationStatus: String, Sendable {
		case `default`
		case error
		case warning
		case success
	}

	public struct ValidationMessages: Sendable {
		let error: String?
		let warning: String?
		let success: String?

		public init(error: String? = nil, warning: String? = nil, success: String? = nil) {
			self.error = error
			self.warning = warning
			self.success = success
		}
	}

	public init(
		id: String,
		labelIcon: String? = nil,
		optional: Bool = false,
		optionalFlag: String = "(optional)",
		hideLabel: Bool = false,
		isFieldset: Bool = false,
		disabled: Bool = false,
		status: ValidationStatus = .default,
		messages: ValidationMessages = ValidationMessages(),
		labelFontWeight: CSSFontWeight = fontWeightBold,
		labelFontSize: Length = fontSizeMedium16,
		class: String = "",
		@HTMLBuilder label: () -> [HTMLProtocol],
		@HTMLBuilder description: () -> [HTMLProtocol] = { [] },
		@HTMLBuilder input: () -> [HTMLProtocol],
		@HTMLBuilder helpText: () -> [HTMLProtocol] = { [] }
	) {
		self.id = id
		self.labelIcon = labelIcon
		self.optional = optional
		self.optionalFlag = optionalFlag
		self.hideLabel = hideLabel
		self.isFieldset = isFieldset
		self.disabled = disabled
		self.status = status
		self.messages = messages
		self.labelFontWeight = labelFontWeight
		self.labelFontSize = labelFontSize
		self.`class` = `class`
		self.labelContent = label()
		self.descriptionContent = description()
		self.inputContent = input()
		self.helpTextContent = helpText()
	}

	@CSSBuilder
	private func fieldViewCSS() -> [CSSProtocol] {
		display(.flex)
		flexDirection(.column)
		gap(spacing8)

		if disabled {
			opacity(opacityMedium)
		}
	}

	@CSSBuilder
	private func fieldInputWrapperCSS() -> [CSSProtocol] {
		display(.block)
	}

	@CSSBuilder
	private func fieldHelpTextCSS() -> [CSSProtocol] {
		display(.block)
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(disabled ? colorDisabled : colorSubtle)
	}

	@CSSBuilder
	private func fieldValidationMessageCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.flexStart)
		gap(spacing4)
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
	}

	@CSSBuilder
	private func fieldValidationIconCSS() -> [CSSProtocol] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		flexShrink(0)
		fontWeight(fontWeightBold)
	}

	@CSSBuilder
	private func fieldValidationTextCSS() -> [CSSProtocol] {
		flex(1)
	}

	public func render(indent: Int = 0) -> String {
		let hasDescription = !descriptionContent.isEmpty
		let hasHelpText = !helpTextContent.isEmpty
		let descriptionId = hasDescription ? "\(id)-description" : nil
		let helpTextId = hasHelpText ? "\(id)-help-text" : nil

		if isFieldset {
			return fieldset {
				LabelView(
					icon: labelIcon,
					optional: optional,
					optionalFlag: optionalFlag,
					visuallyHidden: hideLabel,
					isLegend: true,
					descriptionId: descriptionId,
					disabled: disabled,
					labelFontWeight: labelFontWeight,
					labelFontSize: labelFontSize
				) {
					labelContent
				} description: {
					if hasDescription {
						descriptionContent
					}
				}

				div {
					inputContent
				}
				.class("field-input-wrapper")
				.style {
					fieldInputWrapperCSS()
				}

				if hasHelpText {
					div { helpTextContent }
						.class("field-help-text")
						.id(helpTextId ?? "")
						.style {
							fieldHelpTextCSS()
						}
				}

				if status == .error, let errorMsg = messages.error {
					div {
						span { "⚠" }
							.class("field-validation-icon")
							.ariaHidden(true)
							.style {
								fieldValidationIconCSS()
							}

						span { errorMsg }
							.class("field-validation-text")
							.style {
								fieldValidationTextCSS()
							}
					}
					.class("field-validation-message")
					.style {
						fieldValidationMessageCSS()
						color(colorRed)
					}
				}

				if status == .warning, let warningMsg = messages.warning {
					div {
						span { "⚠" }
							.class("field-validation-icon")
							.ariaHidden(true)
							.style {
								fieldValidationIconCSS()
							}

						span { warningMsg }
							.class("field-validation-text")
							.style {
								fieldValidationTextCSS()
							}
					}
					.class("field-validation-message")
					.style {
						fieldValidationMessageCSS()
						color(colorOrange)
					}
				}

				if status == .success, let successMsg = messages.success {
					div {
						span { "✓" }
							.class("field-validation-icon")
							.ariaHidden(true)
							.style {
								fieldValidationIconCSS()
							}

						span { successMsg }
							.class("field-validation-text")
							.style {
								fieldValidationTextCSS()
							}
					}
					.class("field-validation-message")
					.style {
						fieldValidationMessageCSS()
						color(colorGreen)
					}
				}
			}
			.class(`class`.isEmpty ? "field-view" : "field-view \(`class`)")
			.disabled(disabled)
			.style {
				margin(0)
				padding(0)
				border(.none)
				minWidth(0)
				fieldViewCSS()
			}
			.render(indent: indent)
		} else {
			return div {
				LabelView(
					icon: labelIcon,
					optional: optional,
					optionalFlag: optionalFlag,
					visuallyHidden: hideLabel,
					isLegend: false,
					inputId: id,
					descriptionId: descriptionId,
					disabled: disabled,
					labelFontWeight: labelFontWeight,
					labelFontSize: labelFontSize
				) {
					labelContent
				} description: {
					if hasDescription {
						descriptionContent
					}
				}

				div {
					inputContent
				}
				.class("field-input-wrapper")
				.style {
					fieldInputWrapperCSS()
				}

				if hasHelpText {
					div { helpTextContent }
						.class("field-help-text")
						.id(helpTextId ?? "")
						.style {
							fieldHelpTextCSS()
						}
				}

				if status == .error, let errorMsg = messages.error {
					div {
						span { "⚠" }
							.class("field-validation-icon")
							.ariaHidden(true)
							.style {
								fieldValidationIconCSS()
							}

						span { errorMsg }
							.class("field-validation-text")
							.style {
								fieldValidationTextCSS()
							}
					}
					.class("field-validation-message")
					.style {
						fieldValidationMessageCSS()
						color(colorRed)
					}
				}

				if status == .warning, let warningMsg = messages.warning {
					div {
						span { "⚠" }
							.class("field-validation-icon")
							.ariaHidden(true)
							.style {
								fieldValidationIconCSS()
							}

						span { warningMsg }
							.class("field-validation-text")
							.style {
								fieldValidationTextCSS()
							}
					}
					.class("field-validation-message")
					.style {
						fieldValidationMessageCSS()
						color(colorOrange)
					}
				}

				if status == .success, let successMsg = messages.success {
					div {
						span { "✓" }
							.class("field-validation-icon")
							.ariaHidden(true)
							.style {
								fieldValidationIconCSS()
							}

						span { successMsg }
							.class("field-validation-text")
							.style {
								fieldValidationTextCSS()
							}
					}
					.class("field-validation-message")
					.style {
						fieldValidationMessageCSS()
						color(colorGreen)
					}
				}
			}
			.class(`class`.isEmpty ? "field-view" : "field-view \(`class`)")
			.style {
				fieldViewCSS()
			}
			.render(indent: indent)
		}
	}
}

#endif
