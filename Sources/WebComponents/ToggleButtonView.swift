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
	let quiet: Bool
	let disabled: Bool
	let iconOnly: Bool
	let ariaLabel: String?
	let ariaExpanded: Bool?
	let `class`: String
	
	public init(
		label: String,
		icon: (any HTML)? = nil,
		modelValue: Bool = false,
		quiet: Bool = false,
		disabled: Bool = false,
		iconOnly: Bool = false,
		ariaLabel: String? = nil,
		ariaExpanded: Bool? = nil,
		class: String = ""
	) {
		self.label = label
		self.icon = icon
		self.modelValue = modelValue
		self.quiet = quiet
		self.disabled = disabled
		self.iconOnly = iconOnly
		self.ariaLabel = ariaLabel
		self.ariaExpanded = ariaExpanded
		self.`class` = `class`
	}

	@CSSBuilder
	private func toggleButtonViewCSS(_ isIconOnly: Bool) -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		gap(spacingHorizontalButton)
		fontFamily(fontFamilyBase)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightBold)
		lineHeight(1)
		textDecoration(.none)
		textAlign(.center)
		verticalAlign(.middle)
		whiteSpace(.nowrap)
		userSelect(.none)
		boxSizing(.borderBox)

		// Size
		minWidth(px(32))
		minHeight(px(32))

		// Border
		borderWidth(borderWidthBase)
		borderStyle(.solid)
		borderRadius(borderRadiusBase)

		// Interaction
		cursor(.pointer)
		transition(.all, s(0.1), .ease)

		// Padding
		if isIconOnly {
			padding(0)
			width(px(32))
			height(px(32))
		} else {
			padding(0, spacingHorizontalButton)
		}

		// Normal style (default)
		if !quiet {
			backgroundColor(backgroundColorInteractive)
			color(colorBase)
			borderColor(borderColorBase)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorInteractiveHover).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorInteractiveActive).important()
				color(colorEmphasized).important()
				borderColor(borderColorProgressive).important()
			}

			// Toggled ON state (aria-pressed="true")
			attribute("[aria-pressed=\"true\"]") {
				backgroundColor(backgroundColorProgressive).important()
				color(colorInverted).important()
				borderColor(borderColorProgressive).important()
			}

			attribute("[aria-pressed=\"true\"]:hover:not(:disabled)") {
				backgroundColor(backgroundColorProgressiveHover).important()
				borderColor(borderColorProgressiveHover).important()
			}

			attribute("[aria-pressed=\"true\"]:active:not(:disabled)") {
				backgroundColor(backgroundColorProgressiveActive).important()
				borderColor(borderColorProgressiveActive).important()
			}
		} else {
			// Quiet style - more minimal
			backgroundColor(.transparent)
			color(colorBase)
			borderColor(.transparent)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorInteractiveSubtle).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorInteractiveSubtleActive).important()
				color(colorEmphasized).important()
			}

			// Toggled ON state for quiet (aria-pressed="true")
			attribute("[aria-pressed=\"true\"]") {
				backgroundColor(backgroundColorProgressiveSubtle).important()
				color(colorProgressive).important()
				borderColor(.transparent).important()
			}

			attribute("[aria-pressed=\"true\"]:hover:not(:disabled)") {
				backgroundColor(backgroundColorProgressiveSubtleHover).important()
			}

			attribute("[aria-pressed=\"true\"]:active:not(:disabled)") {
				backgroundColor(backgroundColorProgressiveSubtleActive).important()
				color(colorProgressiveActive).important()
			}
		}

		// Focus state
		pseudoClass(.focus) {
			outline(borderWidthThick, .solid, colorProgressive).important()
			borderColor(borderColorProgressive).important()
		}

		// Disabled state
		pseudoClass(.disabled) {
			color(colorDisabled).important()
			backgroundColor(backgroundColorDisabled).important()
			borderColor(borderColorDisabled).important()
			cursor(.default).important()
			pointerEvents(.none).important()
		}
	}

	@CSSBuilder
	private func toggleButtonIconCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconSmall)
		height(sizeIconSmall)
	}

	@CSSBuilder
	private func toggleButtonLabelHiddenCSS() -> [CSS] {
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

	public func render(indent: Int = 0) -> String {
		let isIconOnly = iconOnly || (icon != nil && label.isEmpty)

		var btn = button {
			if let icon = icon {
				span { icon }
					.class("toggle-button-icon")
					.ariaHidden(true)
					.style {
						toggleButtonIconCSS()
					}
			}

			if !label.isEmpty {
				span { label }
					.class(isIconOnly ? "toggle-button-label-hidden" : "toggle-button-label")
					.style {
						if isIconOnly {
							toggleButtonLabelHiddenCSS()
						}
					}
			}
		}
		.type(.button)
		.class(`class`.isEmpty ? "toggle-button-view" : "toggle-button-view \(`class`)")
		.data("toggle-button", true)
		.ariaPressed(modelValue)
		.disabled(disabled)
		.style {
			toggleButtonViewCSS(isIconOnly)
		}

		// Icon-only buttons require aria-label for accessibility
		if isIconOnly {
			btn = btn.ariaLabel(ariaLabel ?? label)
		} else if let ariaLbl = ariaLabel {
			btn = btn.ariaLabel(ariaLbl)
		}

		// Add aria-expanded if provided (for MenuButton integration)
		if let expanded = ariaExpanded {
			btn = btn.ariaExpanded(expanded)
		}

		return btn.render(indent: indent)
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
		_ = button.on(.click) { [self] _ in
			self.toggle()
		}

		// Keyboard events (Enter and Space)
		_ = button.on(.keydown) { [self] (event: CallbackString) in
			event.withCString { eventPtr in
				let key = String(cString: eventPtr)
				if stringEquals(key, "Enter") || stringEquals(key, " ") {
					self.toggle()
				}
			}
		}
	}

	private func toggle() {
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
