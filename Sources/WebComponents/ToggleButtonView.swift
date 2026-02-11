#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A button that can be toggled on and off with state persistence.
public struct ToggleButtonView: HTMLProtocol {
	let label: String
	let icon: (any HTMLProtocol)?
	let modelValue: Bool
	let weight: ButtonView.ButtonWeight
	let disabled: Bool
	let iconOnly: Bool
	let ariaLabel: String?
	let ariaExpanded: Bool?
	let indicateSelection: Bool
	let size: ButtonView.ButtonSize
	var `class`: String
	let labelFontWeight: CSSFontWeight
	
	public init(
		label: String,
		icon: (any HTMLProtocol)? = nil,
		modelValue: Bool = false,
		weight: ButtonView.ButtonWeight = .subtle,
		disabled: Bool = false,
		iconOnly: Bool = false,
		ariaLabel: String? = nil,
		ariaExpanded: Bool? = nil,
		indicateSelection: Bool = true,
		size: ButtonView.ButtonSize = .medium,
		class: String = "",
		labelFontWeight: CSSFontWeight = fontWeightBold
	) {
		self.label = label
		self.icon = icon
		self.modelValue = modelValue
		self.weight = weight
		self.disabled = disabled
		self.iconOnly = iconOnly
		self.ariaLabel = ariaLabel
		self.ariaExpanded = ariaExpanded
		self.indicateSelection = indicateSelection
		self.size = size
		self.class = `class`
		self.labelFontWeight = labelFontWeight
	}

	public func render(indent: Int = 0) -> String {
		let isIconOnly = iconOnly || (icon != nil && label.isEmpty)
		let fullClass = `class`.isEmpty ? "toggle-button-view" : "toggle-button-view \(`class`)"
		
		return div {
            ButtonView(
                label: "",
                weight: weight,
                size: size,
                disabled: disabled,
                ariaLabel: ariaLabel ?? label,
                class: "",
                labelFontWeight: self.labelFontWeight
            ) {
                if let icon = icon {
                    span { icon }
                        .class("button-icon")
                        .ariaHidden(true)
                        .style {
                            display(.flex)
                            alignItems(.center)
                            justifyContent(.center)
                            
                            if size == .small {
                                width(sizeIconXSmall)
                                height(sizeIconXSmall)
                            } else if size == .medium {
                                width(sizeIconSmall)
                                height(sizeIconSmall)
                            } else if size == .large {
                                width(sizeIconMedium)
                                height(sizeIconMedium)
                            }
                        }
                }
                
                if !label.isEmpty {
                    span { label }
                        .class(isIconOnly ? "toggle-button-label-hidden" : "toggle-button-label")
                }
            }
        }
        .class(fullClass)
        .data("toggle-button", "true")
        .ariaPressed(modelValue)
        .ariaExpanded(ariaExpanded ?? false)
        .style {
            toggleStateCSS()
        }
        .render(indent: indent)
    }
	
	@CSSBuilder
	private func toggleStateCSS() -> [CSSProtocol] {
		// Toggle-specific state styling
		// Subtle/solid toggled state
		if weight == .subtle || weight == .solid {
            if indicateSelection {
                attribute(ariaPressed(true)) {
                    color(colorInverted).important()
                    borderColor(borderColorBlue).important()
                }
            }
		} else { // quiet or plain
            if indicateSelection {
                // Quiet style toggled state
                attribute(ariaPressed(true)) {
                    backgroundColor(backgroundColorBlueSubtle).important()
                    color(colorBlue).important()
                    borderColor(.transparent).important()
                }

                attribute(ariaPressed(true), .hover, not(.disabled)) {
                    backgroundColor(backgroundColorBlueSubtleHover).important()
                    color(colorBlueHover).important()
                }

                attribute(ariaPressed(true), .active, not(.disabled)) {
                    backgroundColor(backgroundColorBlueSubtleActive).important()
                    color(colorBlueActive).important()
                }
            }
		}

		// Accessibility hidden label styling
		descendant(".toggle-button-label-hidden") {
			position(.absolute)
			width(px(1))
			height(px(1))
			padding(0)
			margin(px(-1))
			overflow(.hidden)
			clip(rect(0, 0, 0, 0))
			whiteSpace(.nowrap)
			borderWidth(0)
		}
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

private class ToggleButtonInstance: @unchecked Sendable {
	private var button: Element
	private var modelValue: Bool = false

	init(button: Element) {
		self.button = button

		// Get initial state from aria-pressed
		if let ariaPressed = button.getAttribute("aria-pressed") {
			modelValue = stringEquals(ariaPressed, "true")
		}

		bindEvents()
	}

	private func bindEvents() {
		// Click event
		_ = button.addEventListener(.click) { [self] _ in
			self.toggle()
		}

		// Keyboard events (Enter and Space)
		_ = button.addEventListener(.keydown) { [self] (event: CallbackString) in
			event.withCString { eventPtr in
				let key = String(cString: eventPtr)
				if stringEquals(key, "Enter") || stringEquals(key, " ") {
					self.toggle()
				}
			}
		}
	}

	private func toggle() {
		// Re-read current state from DOM to stay in sync with other hydrators that might
		// have changed the state during initialization or via system preference observers
		if let ariaPressed = button.getAttribute("aria-pressed") {
			modelValue = stringEquals(ariaPressed, "true")
		}
		
		modelValue.toggle()
		button.setAttribute("aria-pressed", modelValue ? "true" : "false")

		// Emit custom event for update:modelValue
		let event = CustomEvent(type: "toggle-button-update", detail: modelValue ? "true" : "false")
		button.dispatchEvent(event)
	}
}

public class ToggleButtonHydration: @unchecked Sendable {
	private var instances: [ToggleButtonInstance] = []

	public init() {
		hydrateAllToggleButtons()
	}

	private func hydrateAllToggleButtons() {
		let allButtons = document.querySelectorAll("[data-toggle-button=\"true\"]")

		for button in allButtons {
			let instance = ToggleButtonInstance(button: button)
			instances.append(instance)
		}
	}
}

#endif
