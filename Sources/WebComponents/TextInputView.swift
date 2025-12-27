#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// TextInput component following Wikimedia Codex design system specification
/// A form element that lets users input and edit a single-line text value.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/text-input.html
public struct TextInputView: HTML {
	let id: String
	let name: String
	let placeholder: String
	let value: String
	let type: InputType
	let status: ValidationStatus
	let disabled: Bool
	let readonly: Bool
	let required: Bool
	let clearable: Bool
	let startIcon: String?
	let endIcon: String?
	let `class`: String

	public enum InputType: String, Sendable {
		case text
		case search
		case number
		case email
		case password
		case tel
		case url
		case week
		case month
		case date
		case datetimeLocal = "datetime-local"
		case time
	}

	public enum ValidationStatus: String, Sendable {
		case `default`
		case error
	}

	public init(
		id: String,
		name: String,
		placeholder: String = "",
		value: String = "",
		type: InputType = .text,
		status: ValidationStatus = .default,
		disabled: Bool = false,
		readonly: Bool = false,
		required: Bool = false,
		clearable: Bool = false,
		startIcon: String? = nil,
		endIcon: String? = nil,
		class: String = ""
	) {
		self.id = id
		self.name = name
		self.placeholder = placeholder
		self.value = value
		self.type = type
		self.status = status
		self.disabled = disabled
		self.readonly = readonly
		self.required = required
		self.clearable = clearable
		self.startIcon = startIcon
		self.endIcon = endIcon
		self.`class` = `class`
	}

	@CSSBuilder
	private func textInputViewCSS() -> [CSS] {
		position(.relative)
		display(.inlineBlock)
		width(perc(100))
	}

	@CSSBuilder
	private func textInputInputCSS(_ disabled: Bool, _ readonly: Bool, _ status: ValidationStatus, _ hasStartIcon: Bool, _ hasEndIcon: Bool, _ clearable: Bool) -> [CSS] {
		width(perc(100))
		minHeight(minSizeInteractivePointer)
		padding(spacing8, spacing12)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightSmall22)
		color(disabled ? colorDisabled : colorBase)
		backgroundColor(disabled ? backgroundColorDisabled : (readonly ? backgroundColorNeutralSubtle : backgroundColorBase))
		border(borderWidthBase, .solid, status == .error ? borderColorError : (disabled ? borderColorDisabled : borderColorInputBinary))
		borderRadius(borderRadiusBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		outline(.none)
		cursor(disabled ? cursorBaseDisabled : cursorBase)
		boxSizing(.borderBox)

		if hasStartIcon {
			paddingLeft(calc("\(spacing12.value) + \(sizeIconMedium.value) + \(spacing8.value)")).important()
		}

		if hasEndIcon || clearable {
			paddingRight(calc("\(spacing12.value) + \(sizeIconMedium.value) + \(spacing8.value)")).important()
		}

		pseudoElement(.placeholder) {
			color(colorPlaceholder).important()
			opacity(opacityIconPlaceholder).important()
		}

		pseudoClass(.focus, not(.disabled), not(.readOnly)) {
			borderColor(borderColorProgressiveFocus).important()
			boxShadow(px(0), px(0), px(0), px(1), boxShadowColorProgressiveFocus).important()
		}

		pseudoClass(.hover, not(.disabled), not(.readOnly)) {
			borderColor(borderColorInputBinaryHover).important()
		}
	}

	@CSSBuilder
	private func textInputIconCSS(_ isStartIcon: Bool) -> [CSS] {
		position(.absolute)
		top(perc(50))
		transform(translateY(perc(-50)))
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconMedium)
		height(sizeIconMedium)
		color(colorSubtle)
		pointerEvents(.none)

		if isStartIcon {
			left(spacing12)
		} else {
			right(spacing12)
		}
	}

	@CSSBuilder
	private func textInputClearButtonCSS(_ disabled: Bool) -> [CSS] {
		position(.absolute)
		top(perc(50))
		right(spacing12)
		transform(translateY(perc(-50)))
		display(.none)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconMedium)
		height(sizeIconMedium)
		padding(0)
		backgroundColor(.transparent)
		border(.none)
		borderRadius(borderRadiusCircle)
		color(colorSubtle)
		cursor(disabled ? cursorBaseDisabled : cursorBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

		pseudoClass(.hover, not(.disabled)) {
			backgroundColor(backgroundColorInteractiveSubtleHover).important()
			color(colorBase).important()
		}

		pseudoClass(.active, not(.disabled)) {
			backgroundColor(backgroundColorInteractiveSubtleActive).important()
		}

		pseudoClass(.focus) {
			outline(px(2), .solid, borderColorProgressiveFocus).important()
			outlineOffset(px(-2)).important()
		}

		if disabled {
			opacity(opacityMedium).important()
		}
	}

	public func render(indent: Int = 0) -> String {
		let hasStartIcon = startIcon != nil
		let hasEndIcon = endIcon != nil
		let htmlInputType = getHTMLInputType(type)

		var container = div {
			if let icon = startIcon {
				span { icon }
					.class("text-input-start-icon")
					.ariaHidden(true)
					.style {
						textInputIconCSS(true)
					}
			}

			input()
				.type(htmlInputType)
				.id(id)
				.name(name)
				.placeholder(placeholder)
				.value(value)
				.disabled(disabled)
				.readonly(readonly)
				.required(required)
				.class("text-input-input")
				.style {
					textInputInputCSS(disabled, readonly, status, hasStartIcon, hasEndIcon, clearable)
				}

			if clearable {
				button {
					span { "×" }
						.ariaHidden(true)
				}
				.type(.button)
				.class("text-input-clear-button")
				.ariaLabel("Clear")
				.tabindex(-1)
				.style {
					textInputClearButtonCSS(disabled)
				}
			}

			if let icon = endIcon {
				span { icon }
					.class("text-input-end-icon")
					.ariaHidden(true)
					.style {
						textInputIconCSS(false)
					}
			}
		}
		.class(`class`.isEmpty ? "text-input-view" : "text-input-view \(`class`)")

		if status == .error {
			container = container.data("status", "error")
		}

		if clearable {
			container = container.data("clearable", "true")
		}

		return container.style {
			textInputViewCSS()
		}
		.render(indent: indent)
	}

	private func getHTMLInputType(_ type: InputType) -> HTMLInput.`Type` {
		switch type {
		case .text: return .text
		case .search: return .search
		case .number: return .number
		case .email: return .email
		case .password: return .password
		case .tel: return .tel
		case .url: return .url
		case .week: return .week
		case .month: return .month
		case .date: return .date
		case .datetimeLocal: return .datetimeLocal
		case .time: return .time
		}
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

private class TextInputInstance: @unchecked Sendable {
	private var textInput: Element
	private var input: Element?
	private var clearButton: Element?
	private var isClearable: Bool = false

	init(textInput: Element) {
		self.textInput = textInput

		input = textInput.querySelector(".text-input-input")
		clearButton = textInput.querySelector(".text-input-clear-button")

		// Check if clearable
		if let clearableAttr = textInput.getAttribute("data-clearable") {
			isClearable = stringEquals(clearableAttr, "true")
		}

		if isClearable {
			bindClearableEvents()
			// Update clear button visibility based on initial value
			updateClearButtonVisibility()
		}
	}

	private func bindClearableEvents() {
		guard let input = input, let clearButton = clearButton else { return }

		// Show/hide clear button based on input value
		_ = input.on(.input) { [self] _ in
			self.updateClearButtonVisibility()
		}

		// Clear input when clear button is clicked
		_ = clearButton.on(.click) { [self] _ in
			guard let input = self.input else { return }
			input.value = ""
			self.updateClearButtonVisibility()
			input.focus()

			// Dispatch input event for reactivity
			input.dispatchEvent(Event.input)

			// Dispatch custom clear event
			let clearEvent = CustomEvent(type: "text-input-clear", detail: "")
			self.textInput.dispatchEvent(clearEvent)
		}

		// Prevent clear button from taking focus away from input
		_ = clearButton.on(.mousedown) { event in
			event.preventDefault()
		}
	}

	private func updateClearButtonVisibility() {
		guard let input = input, let clearButton = clearButton else { return }

		if !stringEquals(input.value, "") {
			clearButton.style.display(.flex)
		} else {
			clearButton.style.display(.none)
		}
	}
}

public class TextInputHydration: @unchecked Sendable {
	private var instances: [TextInputInstance] = []

	public init() {
		hydrateAllTextInputs()
	}

	private func hydrateAllTextInputs() {
		let allTextInputs = document.querySelectorAll(".text-input-view")

		for textInput in allTextInputs {
			let instance = TextInputInstance(textInput: textInput)
			instances.append(instance)
		}
	}
}

#endif
