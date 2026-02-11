#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A SearchInput allows users to enter and submit a search query.
public struct SearchInputView: HTMLProtocol {
	let modelValue: String
	let useButton: Bool
	let hideIcon: Bool
	let clearable: Bool
	let buttonLabel: String
	let disabled: Bool
	let status: ValidationStatus
	let placeholder: String
	let `class`: String

	public enum ValidationStatus: String, Sendable {
		case `default`
		case error
	}

	public init(
		modelValue: String = "",
		useButton: Bool = false,
		hideIcon: Bool = false,
		clearable: Bool = false,
		buttonLabel: String = "",
		disabled: Bool = false,
		status: ValidationStatus = .default,
		placeholder: String = "",
		class: String = ""
	) {
		self.modelValue = modelValue
		self.useButton = useButton
		self.hideIcon = hideIcon
		self.clearable = clearable
		self.buttonLabel = buttonLabel.isEmpty ? "Search" : buttonLabel
		self.disabled = disabled
		self.status = status
		self.placeholder = placeholder
		self.`class` = `class`
	}

	@CSSBuilder
	private func searchInputViewCSS(_ useButton: Bool) -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		position(.relative)
		width(perc(100))

		if useButton {
			gap(spacing8)
		}
	}

	@CSSBuilder
	private func searchInputWrapperCSS(_ useButton: Bool) -> [CSSProtocol] {
		position(.relative)
		display(.flex)
		alignItems(.center)

		if useButton {
			flexGrow(1)
		} else {
			width(perc(100))
		}
	}

	@CSSBuilder
	private func searchInputCSS(_ hasStartIcon: Bool, _ clearable: Bool, _ status: ValidationStatus) -> [CSSProtocol] {
		width(perc(100))
		minHeight(minSizeInteractivePointer)
		padding(spacing12, spacing16)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightSmall22)
		color(colorBase)
		backgroundColor(backgroundColorBase)
		border(borderWidthBase, .solid, borderColorSubtle)
		borderRadius(borderRadiusBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		boxSizing(.borderBox)

		if hasStartIcon {
			paddingInlineStart(px(36))
		}

		if clearable {
			paddingInlineEnd(spacing64)  // Increased to accommodate both icons
		}

		if status == .error {
			borderColor(borderColorRed)
		}

		// Hide native WebKit search cancel button
		pseudoElement(.webkitSearchCancelButton) {
			display(.none).important()
		}

		pseudoElement(.placeholder) {
			color(colorPlaceholder).important()
			opacity(1).important()
		}

		pseudoClass(.hover) {
			borderColor(borderColorInteractive).important()
		}

		pseudoClass(.focus) {
			outline(borderWidthBase, .solid, borderColorBlue).important()
			outlineOffset(px(-2)).important()
			borderColor(borderColorBlue).important()
		}

		pseudoClass(.disabled) {
			backgroundColor(backgroundColorDisabled).important()
			color(colorDisabled).important()
			borderColor(borderColorDisabled).important()
			cursor(cursorBaseDisabled).important()
		}
	}

	@CSSBuilder
	private func searchInputStartIconCSS() -> [CSSProtocol] {
		position(.absolute)
		insetInlineStart(spacing4)
		marginInlineStart(spacing8)
		top(perc(50))
		transform("translateY(-50%)")
		width(sizeIconMedium)
		height(sizeIconMedium)
		padding(spacing8)
		color(colorPlaceholder)
		pointerEvents(.none)
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
	}

	@CSSBuilder
	private func searchInputViewDetailsIconCSS() -> [CSSProtocol] {
		position(.absolute)
		right(spacing40)  // Position to the left of clear button
		top(perc(50))
		transform(translateY("-\(perc(50))"))
		width(sizeIconMedium)
		height(sizeIconMedium)
		padding(spacing8)
		color(colorSubtle)
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		pointerEvents(.none)
	}

	@CSSBuilder
	private func searchInputClearButtonCSS() -> [CSSProtocol] {
		position(.absolute)
		insetInlineEnd(spacing4)
		marginInlineEnd(spacing8)
		top(perc(50))
		transform(translateY("-\(perc(50))"))
		width(sizeIconMedium)
		height(sizeIconMedium)
		padding(spacing8)
		backgroundColor(.transparent)
		border(.none)
		borderRadius(borderRadiusBase)
		cursor(cursorBaseHover)
		color(colorDisabled)
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

		pseudoClass(.hover) {
			color(colorBlue).important()
			cursor(cursorBaseHover).important()

			// Icon hover color when button is enabled
			descendant(".icon-view") {
				color(colorBlue).important()
			}
		}

		pseudoClass(.active) {
			color(colorBase).important()
		}

		pseudoClass(.focus) {
			outline(borderWidthBase, .solid, outlineColorBlueFocus).important()
			outlineOffset(px(4)).important()
		}

		pseudoClass(.disabled) {
			opacity(opacityIconBaseDisabled).important()
			color(colorDisabled).important()
			cursor(.default).important()

			// Icon hover color when button is disabled - more specific to override IconView default
			descendant(".icon-view") {
				color(colorDisabled).important()

				pseudoClass(.hover) {
					color(colorDisabled).important()
				}
			}
		}
	}

	@CSSBuilder
	private func searchInputButtonCSS(_ disabled: Bool) -> [CSSProtocol] {
		minHeight(minSizeInteractivePointer)
		padding(spacing12, spacing16)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightBold)
		lineHeight(lineHeightSmall22)
		color(colorBlue)
		backgroundColor(.transparent)
		border(borderWidthBase, .solid, borderColorBlue)
		borderRadius(borderRadiusBase)
		cursor(disabled ? cursorBaseDisabled : cursorBaseHover)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		whiteSpace(.nowrap)

		if disabled {
			color(colorDisabled)
			borderColor(borderColorDisabled)
			cursor(cursorBaseDisabled)
		} else {
			pseudoClass(.hover) {
				backgroundColor(backgroundColorBlueSubtle).important()
			}

			pseudoClass(.active) {
				backgroundColor(backgroundColorBlueActive).important()
				color(colorInverted).important()
				borderColor(borderColorBlueActive).important()
			}

			pseudoClass(.focus) {
				outline(borderWidthThick, .solid, borderColorBlue).important()
				outlineOffset(px(1)).important()
			}
		}
	}

	public func render(indent: Int = 0) -> String {
		return div {
			div {
				if !hideIcon {
					span {
						IconView(
							icon: { [SearchIconView()] },
							size: .medium
						)
					}
					.class("search-input-start-icon")
					.ariaHidden(true)
					.style {
						searchInputStartIconCSS()
					}
				}

				input()
					.type(.search)
					.class("search-input")
					.value(modelValue)
					.placeholder(placeholder)
					.disabled(disabled)
					.ariaInvalid(status == .error)
					.style {
						searchInputCSS(!hideIcon, clearable, status)
					}

				if clearable {
					// View details icon (positioned to the left of clear button)
					span {
						IconView(
							icon: { [ViewDetailsIconView()] },
							size: .medium
						)
					}
					.class("search-input-view-details-icon")
					.ariaHidden(true)
					.style {
						searchInputViewDetailsIconCSS()
					}

					button {
						IconView(
							icon: { [DeleteIconView()] },
							size: .medium
						)
					}
					.type(.button)
					.class("search-input-clear-button")
					.ariaLabel("Clear search")
					.disabled(modelValue.isEmpty)
					.style {
						searchInputClearButtonCSS()
                        if modelValue.isEmpty {
                            opacity(opacityIconBaseDisabled)
                        }
					}
				}
			}
			.class("search-input-wrapper")
			.style {
				searchInputWrapperCSS(useButton)
			}

			if useButton {
				button { buttonLabel }
					.type(.submit)
					.class("search-input-button")
					.disabled(disabled)
					.style {
						searchInputButtonCSS(disabled)
					}
			}
		}
		.class(`class`.isEmpty ? (useButton ? "search-input-view search-input-has-button" : "search-input-view") : (useButton ? "search-input-view search-input-has-button \(`class`)" : "search-input-view \(`class`)"))
		.style {
			searchInputViewCSS(useButton)
		}
		.render(indent: indent)
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

private class SearchInputInstance: @unchecked Sendable {
	private var searchInputElement: Element
	private var inputElement: Element?
	private var clearButton: Element?
	private var submitButton: Element?

	init(searchInput: Element) {
		self.searchInputElement = searchInput
		self.inputElement = searchInput.querySelector(".search-input")
		self.clearButton = searchInput.querySelector(".search-input-clear-button")
		self.submitButton = searchInput.querySelector(".search-input-button")

		bindEvents()
	}

	private func bindEvents() {
		if let input = inputElement {
			_ = input.addEventListener(.input) { [self] _ in
				self.handleInput()
			}

			_ = input.addEventListener(.keydown) { [self] event in
				let key = event.key
				self.handleKeydown(key: key, event: event)
			}
		}

		if let clear = clearButton {
			_ = clear.addEventListener(.click) { [self] _ in
				self.clearInput()
			}
		}

		if let submit = submitButton {
			_ = submit.addEventListener(.click) { [self] _ in
				self.handleSubmit()
			}
		}
	}

	private func handleInput() {
		guard let input = inputElement else { return }
		let value = input.value

		// Update clear button disabled state and styling
		if let clear = clearButton {
			if value.isEmpty {
				clear.disabled = true
				clear.style.opacity(opacityIconBaseDisabled)
				clear.style.cursor(.notAllowed)
			} else {
				clear.disabled = false
				clear.style.opacity(opacityIconBaseSelected)
				clear.style.cursor(cursorBaseHover)
			}
		}

		// Emit input event
		let event = CustomEvent(type: "update:modelValue", detail: value)
		searchInputElement.dispatchEvent(event)
	}

	private func handleKeydown(key: String, event: CallbackString) {
		if stringEquals(key, "Escape") || stringEquals(key, "Esc") {
			clearInput()
		} else if stringEquals(key, "Enter") {
			handleSubmit()
		} else if stringEquals(key, "ArrowDown") {
			console.log("SearchInputView: Arrow key detected: \(key)")
			// Prevent cursor movement in input
			event.preventDefault()
			// Forward navigation keys to parent typeahead
			let customEvent = CustomEvent(type: "arrow-down", detail: key)
			searchInputElement.dispatchEvent(customEvent)
			console.log("SearchInputView: Dispatched arrow-down event")
		} else if stringEquals(key, "ArrowUp") {
			console.log("SearchInputView: Arrow key detected: \(key)")
			// Prevent cursor movement in input
			event.preventDefault()
			// Forward navigation keys to parent typeahead
			let customEvent = CustomEvent(type: "arrow-up", detail: key)
			searchInputElement.dispatchEvent(customEvent)
			console.log("SearchInputView: Dispatched arrow-up event")
		}
	}

	private func clearInput() {
		guard let input = inputElement else { return }
		input.value = ""
		input.focus()
		handleInput()
	}

	private func handleSubmit() {
		guard let input = inputElement else { return }
		let value = input.value

		let event = CustomEvent(type: "submit-click", detail: value)
		searchInputElement.dispatchEvent(event)
	}
}

public class SearchInputHydration: @unchecked Sendable {
	private var instances: [SearchInputInstance] = []

	public init() {
		hydrateAllSearchInputs()
	}

	private func hydrateAllSearchInputs() {
		let allSearchInputs = document.querySelectorAll(".search-input-view")

		for searchInput in allSearchInputs {
			let instance = SearchInputInstance(searchInput: searchInput)
			instances.append(instance)
		}
	}
}

#endif
