#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// ToggleSwitch component following Wikimedia Codex design system specification
/// A ToggleSwitch enables the user to instantly toggle between on and off states.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/toggle-switch.html
///
/// Component Integration:
/// - Integrates LabelView for label and description rendering
public struct ToggleSwitchView: HTML {
	let id: String
	let name: String
	let inputValue: String
	let checked: Bool
	let alignSwitch: Bool
	let hideLabel: Bool
	let disabled: Bool
	let labelContent: [HTML]
	let descriptionContent: [HTML]
	let `class`: String

	public init(
		id: String,
		name: String,
		inputValue: String = "",
		checked: Bool = false,
		alignSwitch: Bool = false,
		hideLabel: Bool = false,
		disabled: Bool = false,
		class: String = "",
		@HTMLBuilder label: () -> [HTML],
		@HTMLBuilder description: () -> [HTML] = { [] }
	) {
		self.id = id
		self.name = name
		self.inputValue = inputValue
		self.checked = checked
		self.alignSwitch = alignSwitch
		self.hideLabel = hideLabel
		self.disabled = disabled
		self.`class` = `class`
		self.labelContent = label()
		self.descriptionContent = description()
	}

	@CSSBuilder
	private func toggleSwitchViewCSS(_ alignSwitch: Bool) -> [CSS] {
		display(.flex)
		alignItems(.center)
		minHeight(minSizeInteractivePointer)
		gap(spacing8)

		if alignSwitch {
			justifyContent(.spaceBetween).important()
		}
	}

	@CSSBuilder
	private func toggleSwitchInputCSS(_ disabled: Bool) -> [CSS] {
		position(.absolute)
		width(px(1))
		height(px(1))
		margin(px(-1))
		padding(0)
		overflow(.hidden)
		clip(rect(0, 0, 0, 0))
		whiteSpace(.nowrap)
		borderWidth(0)
		cursor(disabled ? cursorBaseDisabled : cursorBase)

		pseudoClass(.checked, not(.disabled)) {
			nextSibling(".toggle-switch-switch") {
				backgroundColor(backgroundColorInputBinaryChecked).important()
			}
			selector("+ .toggle-switch-switch .toggle-switch-grip") {
				left(spacingToggleSwitchGripEnd).important()
			}
		}

		pseudoClass(.focus) {
			nextSibling(".toggle-switch-switch") {
				borderColor(borderColorInputBinaryFocus).important()
				boxShadow(px(0), px(0), px(0), px(1), boxShadowColorProgressiveFocus).important()
			}
		}

		pseudoClass(.hover, not(.disabled)) {
			nextSibling(".toggle-switch-switch") {
				borderColor(borderColorInputBinaryHover).important()
			}
		}
	}

	@CSSBuilder
	private func toggleSwitchSwitchCSS(_ disabled: Bool) -> [CSS] {
		position(.relative)
		display(.inlineBlock)
		flexShrink(0)
		width(widthToggleSwitch)
		height(heightToggleSwitch)
		minWidth(minWidthToggleSwitch)
		minHeight(minHeightToggleSwitch)
		backgroundColor(disabled ? backgroundColorDisabled : backgroundColorInteractive)
		border(borderWidthBase, .solid, disabled ? borderColorDisabled : borderColorInputBinary)
		borderRadius(borderRadiusPill)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		cursor(disabled ? cursorBaseDisabled : cursorBase)

		if disabled {
			opacity(opacityMedium).important()
		}
	}

	@CSSBuilder
	private func toggleSwitchGripCSS() -> [CSS] {
		position(.absolute)
		top(perc(50))
		left(spacingToggleSwitchGripStart)
		transform(translateY(perc(-50)))
		width(minSizeToggleSwitchGrip)
		height(minSizeToggleSwitchGrip)
		backgroundColor(colorInvertedFixed)
		borderRadius(borderRadiusCircle)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		boxShadow(boxShadowSmall)
	}

	@CSSBuilder
	private func toggleSwitchLabelWrapperCSS(_ alignSwitch: Bool) -> [CSS] {
		if alignSwitch {
			flex(1).important()
		}
	}

	public func render(indent: Int = 0) -> String {
		let hasDescription = !descriptionContent.isEmpty
		let descriptionId = hasDescription ? "\(id)-description" : nil

		// Create a wrapper div to hold LabelView and apply toggle-specific styles
		let labelWrapper: HTMLDivElement = div {
			LabelView(
				visuallyHidden: hideLabel,
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
		}
		.class("toggle-switch-label-wrapper")
		.style {
			toggleSwitchLabelWrapperCSS(alignSwitch)

			// Override LabelView's bold font weight and add toggle-specific styles
			fontWeight(fontWeightNormal).important()
			cursor(disabled ? cursorBaseDisabled : cursorBase).important()
			userSelect(.none).important()
		}

		return div {
			input()
				.type(.checkbox)
				.id(id)
				.name(name)
				.value(inputValue)
				.checked(checked)
				.disabled(disabled)
				.ariaDescribedby(descriptionId)
				.class("toggle-switch-input")
				.style {
					toggleSwitchInputCSS(disabled)
				}

			span {
				span {}
					.class("toggle-switch-grip")
					.ariaHidden(true)
					.style {
						toggleSwitchGripCSS()
					}
			}
			.class("toggle-switch-switch")
			.ariaHidden(true)
			.style {
				toggleSwitchSwitchCSS(disabled)
			}

			labelWrapper
		}
		.class(`class`.isEmpty ? "toggle-switch-view" : "toggle-switch-view \(`class`)")
		.style {
			toggleSwitchViewCSS(alignSwitch)
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

private class ToggleSwitchInstance: @unchecked Sendable {
	private var toggleSwitch: Element
	private var input: Element?

	init(toggleSwitch: Element) {
		self.toggleSwitch = toggleSwitch
		input = toggleSwitch.querySelector(".toggle-switch-input")

		bindEvents()
	}

	private func bindEvents() {
		guard let input else { return }

		// Dispatch custom change event when toggle state changes
		_ = input.addEventListener(.change) { [self] _ in
			let isChecked = input.hasAttribute("checked")
			let event = CustomEvent(type: "toggle-switch-change", detail: isChecked ? "true" : "false")
			self.toggleSwitch.dispatchEvent(event)
		}
	}
}

public class ToggleSwitchHydration: @unchecked Sendable {
	private var instances: [ToggleSwitchInstance] = []

	public init() {
		hydrateAllToggleSwitches()
	}

	private func hydrateAllToggleSwitches() {
		let allToggleSwitches = document.querySelectorAll(".toggle-switch-view")

		for toggleSwitch in allToggleSwitches {
			let instance = ToggleSwitchInstance(toggleSwitch: toggleSwitch)
			instances.append(instance)
		}
	}
}

#endif
