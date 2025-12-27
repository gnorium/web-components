#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Field component following Wikimedia Codex design system specification
/// A form field with a label, an input or control, and an optional validation message.
/// Provides features for building accessible form fields to collect user input.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/field.html
public struct FieldView: HTML {
	let id: String
	let labelIcon: String?
	let optional: Bool
	let optionalFlag: String
	let hideLabel: Bool
	let isFieldset: Bool
	let disabled: Bool
	let status: ValidationStatus
	let labelContent: [HTML]
	let descriptionContent: [HTML]
	let inputContent: [HTML]
	let helpTextContent: [HTML]
	let messages: ValidationMessages
	let `class`: String

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
		class: String = "",
		@HTMLBuilder label: () -> [HTML],
		@HTMLBuilder description: () -> [HTML] = { [] },
		@HTMLBuilder input: () -> [HTML],
		@HTMLBuilder helpText: () -> [HTML] = { [] }
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
		self.`class` = `class`
		self.labelContent = label()
		self.descriptionContent = description()
		self.inputContent = input()
		self.helpTextContent = helpText()
	}

	@CSSBuilder
	private func fieldViewCSS() -> [CSS] {
		display(.flex)
		flexDirection(.column)
		gap(spacing8)

		if disabled {
			opacity(opacityMedium)
		}
	}

	@CSSBuilder
	private func fieldInputWrapperCSS() -> [CSS] {
		display(.block)
	}

	@CSSBuilder
	private func fieldHelpTextCSS() -> [CSS] {
		display(.block)
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(disabled ? colorDisabled : colorSubtle)
	}

	@CSSBuilder
	private func fieldValidationMessageCSS() -> [CSS] {
		display(.flex)
		alignItems(.flexStart)
		gap(spacing4)
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
	}

	@CSSBuilder
	private func fieldValidationIconCSS() -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		flexShrink(0)
		fontWeight(fontWeightBold)
	}

	@CSSBuilder
	private func fieldValidationTextCSS() -> [CSS] {
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
					disabled: disabled
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
						color(colorError)
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
						color(colorWarning)
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
						color(colorSuccess)
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
					disabled: disabled
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
						color(colorError)
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
						color(colorWarning)
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
						color(colorSuccess)
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
