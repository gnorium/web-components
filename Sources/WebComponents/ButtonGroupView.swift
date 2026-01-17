#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// ButtonGroup component following Wikimedia Codex design system specification
/// A ButtonGroup consists of a set of two or more normal buttons.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/button-group.html
public struct ButtonGroupView: HTML {
	public struct ButtonItem: Sendable {
		public let value: String
		public let label: String
		public let icon: (any HTML)?
		public let disabled: Bool
		public let ariaLabel: String?

		public init(
			value: String,
			label: String,
			icon: (any HTML)? = nil,
			disabled: Bool = false,
			ariaLabel: String? = nil
		) {
			self.value = value
			self.label = label
			self.icon = icon
			self.disabled = disabled
			self.ariaLabel = ariaLabel
		}
	}

	let buttons: [ButtonItem]
	let disabled: Bool
	let `class`: String

	public init(
		buttons: [ButtonItem],
		disabled: Bool = false,
		class: String = ""
	) {
		self.buttons = buttons
		self.disabled = disabled
		self.`class` = `class`
	}

	@CSSBuilder
	private func buttonGroupViewCSS() -> [CSS] {
		display(.inlineFlex)
		flexWrap(.wrap)
	}

	@CSSBuilder
	private func buttonGroupButtonCSS(_ isDisabled: Bool) -> [CSS] {
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
		padding(0, spacingHorizontalButton)

		// Colors - Neutral normal button style
		backgroundColor(backgroundColorInteractive)
		color(colorBase)
		borderWidth(borderWidthBase)
		borderStyle(.solid)
		borderColor(borderColorBase)

		// Interaction
		cursor(.pointer)
		transition(.all, s(0.1), .ease)

		// Hover state
		pseudoClass(.hover, not(.disabled)) {
			backgroundColor(backgroundColorInteractiveHover).important()
		}

		// Active state
		pseudoClass(.active, not(.disabled)) {
			backgroundColor(backgroundColorInteractiveActive).important()
			color(colorEmphasized).important()
			borderColor(borderColorProgressive).important()
		}

		// Focus state
		pseudoClass(.focus) {
			outline(borderWidthThick, .solid, colorProgressive).important()
			borderColor(borderColorProgressive).important()
		}

		// Disabled state
		if isDisabled {
			color(colorDisabled).important()
			backgroundColor(backgroundColorDisabled).important()
			borderColor(borderColorDisabled).important()
			cursor(.default).important()
			pointerEvents(.none).important()
		}
	}

	@CSSBuilder
	private func buttonIconCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconSmall)
		height(sizeIconSmall)
	}

	public func render(indent: Int = 0) -> String {
		div {
			buttons.map { button -> any HTML in
				let isDisabled = disabled || button.disabled

				return div {
					if let icon = button.icon {
						span { icon }
							.class("button-icon")
							.ariaHidden(true)
							.style {
								buttonIconCSS()
							}
					}

					if !button.label.isEmpty {
						span { button.label }
					}
				}
				.class("button-group-button")
				.data("value", button.value)
				.tabindex(isDisabled ? -1 : 0)
				.role(.button)
				.ariaDisabled(isDisabled)
				.ariaLabel(button.ariaLabel ?? button.label)
				.style {
					buttonGroupButtonCSS(isDisabled)
				}
			}
		}
		.class(`class`.isEmpty ? "button-group-view" : "button-group-view \(`class`)")
		.role(.group)
		.style {
			buttonGroupViewCSS()

			// First button - rounded left corners
			selector(".button-group-button:first-child") {
				borderTopLeftRadius(borderRadiusPill).important()
				borderBottomLeftRadius(borderRadiusPill).important()
			}

			// Last button - rounded right corners
			selector(".button-group-button:last-child") {
				borderTopRightRadius(borderRadiusPill).important()
				borderBottomRightRadius(borderRadiusPill).important()
			}

			// Middle buttons - no border radius
			selector(".button-group-button:not(:first-child):not(:last-child)") {
				borderRadius(0).important()
			}

			// Collapse borders between buttons
			selector(".button-group-button:not(:last-child)") {
				marginRight(px(-1)).important()
			}

			// Bring focused/hovered button to front
			selector(".button-group-button:hover") {
				zIndex(1).important()
			}

			selector(".button-group-button:focus") {
				zIndex(2).important()
			}
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

private class ButtonGroupInstance: @unchecked Sendable {
	private var buttons: [Element] = []

	init(group: Element) {
		buttons = Array(group.querySelectorAll(".button-group-button"))
		bindEvents()
	}

	private func bindEvents() {
		for button in buttons {
			// Click event
			_ = button.addEventListener(.click) { [self] _ in
				self.handleClick(button)
			}

			// Keyboard events
			_ = button.addEventListener(.keydown) { [self] (event: CallbackString) in
				self.handleKeydown(button, event: event)
			}
		}
	}

	private func handleClick(_ button: Element) {
		guard let ariaDisabled = button.getAttribute("aria-disabled"),
			  !stringEquals(ariaDisabled, "true") else { return }

		guard let value = button.getAttribute("data-value") else { return }

		// Emit custom event
		let event = CustomEvent(type: "button-group-click", detail: value)
		button.dispatchEvent(event)
	}

	private func handleKeydown(_ button: Element, event: CallbackString) {
		guard let ariaDisabled = button.getAttribute("aria-disabled"),
			  !stringEquals(ariaDisabled, "true") else { return }

		// Handle Enter and Space keys
		event.withCString { eventPtr in
			let eventStr = String(cString: eventPtr)

			if stringEquals(eventStr, "Enter") || stringEquals(eventStr, " ") {
				handleClick(button)
			}
		}
	}
}

public class ButtonGroupHydration: @unchecked Sendable {
	private var instances: [ButtonGroupInstance] = []

	public init() {
		hydrateAllButtonGroups()
	}

	private func hydrateAllButtonGroups() {
		let allGroups = document.querySelectorAll(".button-group-view")

		for group in allGroups {
			let instance = ButtonGroupInstance(group: group)
			instances.append(instance)
		}
	}
}

#endif
