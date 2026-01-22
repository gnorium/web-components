#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// ToggleButton component following Wikimedia Codex design system specification
/// A button that can be toggled on and off with state persistence.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/toggle-button.html
public struct ToggleButtonView: HTML {
	let label: String
	let icon: (any HTML)?
	let modelValue: Bool
	let weight: ButtonView.ButtonWeight
	let disabled: Bool
	let iconOnly: Bool
	let ariaLabel: String?
	let ariaExpanded: Bool?
	let indicateSelection: Bool
	let size: ButtonView.ButtonSize
	var `class`: String
	let buttonFontWeight: CSSFontWeight
	
	public init(
		label: String,
		icon: (any HTML)? = nil,
		modelValue: Bool = false,
		weight: ButtonView.ButtonWeight = .normal,
		disabled: Bool = false,
		iconOnly: Bool = false,
		ariaLabel: String? = nil,
		ariaExpanded: Bool? = nil,
		indicateSelection: Bool = true,
		size: ButtonView.ButtonSize = .medium,
		class: String = "",
		buttonFontWeight: CSSFontWeight = fontWeightBold
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
		self.buttonFontWeight = buttonFontWeight
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
                buttonFontWeight: self.buttonFontWeight
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
	private func toggleStateCSS() -> [CSS] {
		// Toggle-specific state styling
		// Normal style (default) toggled state
		if weight == .normal || weight == .primary {
            if indicateSelection {
                attribute(ariaPressed(true)) {
                    color(colorInverted).important()
                    borderColor(borderColorProgressive).important()
                }
            }
		} else { // quiet or transparent
            if indicateSelection {
                // Quiet style toggled state
                attribute(ariaPressed(true)) {
                    backgroundColor(backgroundColorProgressiveSubtle).important()
                    color(colorProgressive).important()
                    borderColor(.transparent).important()
                }

                attribute(ariaPressed(true), .hover, not(.disabled)) {
                    backgroundColor(backgroundColorProgressiveSubtleHover).important()
                    color(colorProgressiveHover).important()
                }

                attribute(ariaPressed(true), .active, not(.disabled)) {
                    backgroundColor(backgroundColorProgressiveSubtleActive).important()
                    color(colorProgressiveActive).important()
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
