#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// ToggleButtonGroup component following Wikimedia Codex design system specification
/// A ToggleButtonGroup is a group of ToggleButtons that allows single or multi-select.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/toggle-button-group.html
public struct ToggleButtonGroupView: HTML {
	let buttons: [ButtonItem]
	let selectedValues: [String]
	let isMultiSelect: Bool
	let disabled: Bool
	let `class`: String

	public struct ButtonItem: Sendable {
		public let value: String
		public let label: String
		public let icon: String?
		public let disabled: Bool

		public init(value: String, label: String, icon: String? = nil, disabled: Bool = false) {
			self.value = value
			self.label = label
			self.icon = icon
			self.disabled = disabled
		}
	}

	public init(
		buttons: [ButtonItem],
		selectedValues: [String] = [],
		isMultiSelect: Bool = false,
		disabled: Bool = false,
		class: String = ""
	) {
		self.buttons = buttons
		self.selectedValues = selectedValues
		self.isMultiSelect = isMultiSelect
		self.disabled = disabled
		self.`class` = `class`
	}

	@CSSBuilder
	private func toggleButtonGroupViewCSS() -> [CSS] {
		display(.inlineFlex)
		flexWrap(.wrap)
		gap(0)

		// Rounded corners for first/last buttons
		selector(".toggle-button-view:first-child") {
			borderTopLeftRadius(borderRadiusBase).important()
			borderBottomLeftRadius(borderRadiusBase).important()
		}

		selector(".toggle-button-view:last-child") {
			borderTopRightRadius(borderRadiusBase).important()
			borderBottomRightRadius(borderRadiusBase).important()
		}

		// Collapse borders between buttons
		selector(".toggle-button-view:not(:first-child)") {
			marginLeft(calc("-\(borderWidthBase.value)")).important()
		}

		// Bring focused/hovered button to front
		selector(".toggle-button-view:hover") {
			zIndex(1).important()
		}

		selector(".toggle-button-view:focus") {
			zIndex(2).important()
		}
	}

	public func render(indent: Int = 0) -> String {
		var container = div {
			for buttonItem in buttons {
				let isSelected = selectedValues.contains(buttonItem.value)
				let isDisabled = disabled || buttonItem.disabled

				ToggleButtonView(
					label: buttonItem.label,
					icon: buttonItem.icon.map { iconStr in span { iconStr } },
					modelValue: isSelected,
					quiet: false,
					disabled: isDisabled,
					iconOnly: false,
					class: "toggle-button-group-item"
				)
			}
		}
		.class(`class`.isEmpty ? "toggle-button-group-view" : "toggle-button-group-view \(`class`)")
		.role(.group)
		.ariaLabel("Toggle button group")

		if isMultiSelect {
			container = container.data("multi-select", "true")
		}

		return container.style {
			toggleButtonGroupViewCSS()
		}
		.render(indent: indent)
	}
}

#endif

#if os(WASI)

import WebAPIs
import EmbeddedSwiftUtilities

public class ToggleButtonGroupHydration: @unchecked Sendable {
	public init() {}

	public func hydrate() {
		let groups = document.querySelectorAll(".toggle-button-group-view")

		for group in groups {
			let buttons = group.querySelectorAll(".toggle-button")

			for button in buttons {
				_ = button.on(.click) { _ in
					guard let ariaPressed = button.getAttribute("aria-pressed"),
						  !stringEquals(button.getAttribute("disabled") ?? "", "true") else { return }

					let isPressed = stringEquals(ariaPressed, "true")
					let newPressed = !isPressed

					// Check if this is a multi-select group by looking for data-multi-select
					let isMultiSelect = group.getAttribute("data-multi-select") != nil

					if !isMultiSelect {
						// Single select - deselect all other buttons first
						for otherButton in buttons {
							if otherButton.id != button.id {
								otherButton.setAttribute("aria-pressed", "false")
								_ = otherButton.classList.remove("toggle-button-selected")
							}
						}
					}

					// Toggle this button
					button.setAttribute("aria-pressed", newPressed ? "true" : "false")
					if newPressed {
						_ = button.classList.add("toggle-button-selected")
					} else {
						_ = button.classList.remove("toggle-button-selected")
					}

					// Dispatch change event
					guard let value = button.getAttribute("data-value") else { return }
					let event = CustomEvent(type: "toggle-button-change", detail: value)
					group.dispatchEvent(event)
				}

				// Keyboard support
				_ = button.on(.keydown) { event in
					let key = event.key
					if stringEquals(key, "Enter") || stringEquals(key, " ") {
						event.preventDefault()
						button.click()
					}
				}
			}
		}
	}
}

#endif
