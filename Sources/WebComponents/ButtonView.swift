#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Button component following Wikimedia Codex design system specification
/// A Button triggers an action when the user clicks or taps on it.
///
/// Codex Reference: https://doc.wikimedia.org/codex/latest/components/demos/button.html
public struct ButtonView: HTML {
	let label: String
	let action: ButtonAction
	let weight: ButtonWeight
	let size: ButtonSize
	let icon: (any HTML)?
	let iconOnly: Bool
	let disabled: Bool
	let ariaLabel: String?
	let onClick: String?
	let type: ButtonType
	let fullWidth: Bool
	let `class`: String

	/// Button type attribute
	public enum ButtonType: String, Sendable {
		case button
		case submit
		case reset
	}

	/// Button action types following Codex specification
	public enum ButtonAction: String, Sendable {
		/// Neutral buttons for actions that are neutral or secondary in importance
		case `default`
		/// Progressive buttons for actions that lead to the next step in the process
		case progressive
		/// Destructive buttons for actions involving removal or limitation (deleting, blocking)
		case destructive
	}

	/// Button weight (visual prominence) following Codex specification
	public enum ButtonWeight: String, Sendable {
		/// Primary buttons signal the main action - only one per view
		case primary
		/// Normal buttons are the default choice (uses subtle background in Codex)
		case normal
		/// Quiet buttons for easily recognizable actions that don't detract from content
		case quiet
	}

	/// Button sizes following Codex specification
	public enum ButtonSize: String, Sendable {
		/// Small: Use only when space is tight (inline with text, compact layouts). Avoid on touchscreens.
		case small
		/// Medium: Standard button size (default)
		case medium
		/// Large: For accessibility on touchscreens (increases touch area)
		case large

		var minSize: Length {
			switch self {
			case .small: return px(24)
			case .medium: return px(32)
			case .large: return px(44)
			}
		}
	}

	// MARK: - Initialization
    
	/// Create a standard button with text label
	public init(
		label: String,
		action: ButtonAction = .default,
		weight: ButtonWeight = .normal,
		size: ButtonSize = .medium,
		disabled: Bool = false,
		type: ButtonType = .button,
		ariaLabel: String? = nil,
		onClick: String? = nil,
		fullWidth: Bool = false,
		class: String = ""
	) {
		self.label = label
		self.action = action
		self.weight = weight
		self.size = size
		self.icon = nil
		self.iconOnly = false
		self.disabled = disabled
		self.type = type
		self.ariaLabel = ariaLabel
		self.onClick = onClick
		self.fullWidth = fullWidth
		self.`class` = `class`
	}

	/// Create a button with icon and text label
	public init(
		label: String,
		icon: any HTML,
		action: ButtonAction = .default,
		weight: ButtonWeight = .normal,
		size: ButtonSize = .medium,
		disabled: Bool = false,
		type: ButtonType = .button,
		ariaLabel: String? = nil,
		onClick: String? = nil,
		fullWidth: Bool = false,
		class: String = ""
	) {
		self.label = label
		self.action = action
		self.weight = weight
		self.size = size
		self.icon = icon
		self.iconOnly = false
		self.disabled = disabled
		self.type = type
		self.ariaLabel = ariaLabel
		self.onClick = onClick
		self.fullWidth = fullWidth
		self.`class` = `class`
	}

	/// Create an icon-only button
	/// WARNING: Icon-only buttons require aria-label for accessibility
	public init(
		icon: any HTML,
		action: ButtonAction = .default,
		weight: ButtonWeight = .normal,
		size: ButtonSize = .medium,
		disabled: Bool = false,
		type: ButtonType = .button,
		ariaLabel: String,
		onClick: String? = nil,
		fullWidth: Bool = false,
		class: String = ""
	) {
		self.label = ""
		self.action = action
		self.weight = weight
		self.size = size
		self.icon = icon
		self.iconOnly = true
		self.disabled = disabled
		self.type = type
		self.ariaLabel = ariaLabel
		self.onClick = onClick
		self.fullWidth = fullWidth
		self.`class` = `class`
	}

	@CSSBuilder
	private func buttonViewCSS() -> [CSS] {
		// Base button styles
		if fullWidth {
			display(.flex)
		} else {
			display(.inlineFlex)
		}
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
		if fullWidth {
			width(perc(100))
		} else {
			minWidth(size.minSize)
		}
		minHeight(size.minSize)

		// Border
		borderWidth(borderWidthBase)
		borderStyle(.solid)
		borderRadius(borderRadiusPill)

		// Interaction
		cursor(.pointer)
		transition(.all, s(0.1), .ease)

		// Padding based on size and icon-only state
		if iconOnly {
			padding(0)
			width(size.minSize)
			height(size.minSize)
		} else {
			switch size {
				case .small:
					padding(0, spacingHorizontalButtonSmall)
				case .medium:
					padding(0, spacingHorizontalButton)
				case .large:
					padding(0, spacingHorizontalButtonLarge)
			}
		}

		// Action + Weight combinations following Codex design tokens
		applyActionWeightCSS()

		// Focus state
		pseudoClass(.focus) {
			outline(borderWidthBase, .solid, borderColorTransparent).important()
		}

		// Disabled state
		pseudoClass(.disabled) {
			color(colorDisabled).important()
			backgroundColor(backgroundColorDisabled).important()
			borderColor(borderColorDisabled).important()
			cursor(.default).important()
			pointerEvents(.none).important()
		}

		// Icon hover color when button is disabled
		pseudoClass(.disabled) {
			descendant(".icon-view") {
				pseudoClass(.hover) {
					color(colorDisabled).important()
				}
			}
		}
	}

	@CSSBuilder
	private func buttonIconCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		justifyContent(.center)

		if size == .small {
			width(sizeIconXSmall)
			height(sizeIconXSmall)
		} else {
			width(sizeIconSmall)
			height(sizeIconSmall)
		}
	}

	public func render(indent: Int = 0) -> String {
		var classes = [
			"button-view",
			"button-action-\(action.rawValue)",
			"button-weight-\(weight.rawValue)",
			"button-size-\(size.rawValue)"
		]

		if iconOnly {
			classes.append("button-icon-only")
		}

		let effectiveAriaLabel: String? = {
			if let ariaLabel = ariaLabel {
				return ariaLabel
			} else if !label.isEmpty {
				return label
			} else {
				return nil
			}
		}()

		var btn = button {
			if let icon = icon {
				span { icon }
					.class("button-icon")
					.ariaHidden(true)
					.style {
						buttonIconCSS()
					}
			}

			if !label.isEmpty {
				span { label }
			}
		}
		.class(`class`.isEmpty ? "button-view" : "button-view \(`class`)")
		.type(type == .submit ? .submit : type == .reset ? .reset : .button)
		.disabled(disabled)
		.style {
			buttonViewCSS()
		}

		if let ariaLbl = effectiveAriaLabel {
			btn = btn.ariaLabel(ariaLbl)
		}

		if let click = onClick {
			btn = btn.onClick(click)
		}

		return btn.render(indent: indent)
	}

	@CSSBuilder
	private func applyActionWeightCSS() -> [CSS] {
		switch (action, weight) {
		// Default + Normal (Neutral)
		case (.default, .normal):
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

		// Default + Primary
		case (.default, .primary):
			backgroundColor(backgroundColorBase)
			color(colorBase)
			borderColor(borderColorBase)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorNeutralSubtle).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorNeutral).important()
				color(colorEmphasized).important()
				borderColor(borderColorProgressive).important()
			}

		// Default + Quiet
		case (.default, .quiet):
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

		// Progressive + Normal
		case (.progressive, .normal):
			backgroundColor(backgroundColorProgressiveSubtle)
			color(colorProgressive)
			borderColor(borderColorProgressive)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorProgressiveSubtleHover).important()
				borderColor(borderColorProgressiveHover).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorProgressiveSubtleActive).important()
				borderColor(borderColorProgressiveActive).important()
				color(colorProgressiveActive).important()
			}

			pseudoClass(.focus) {
				borderColor(borderColorProgressiveFocus).important()
				boxShadow(boxShadowOutsetSmall, boxShadowColorProgressiveFocus).important()
			}

		// Progressive + Primary
		case (.progressive, .primary):
			backgroundColor(backgroundColorProgressive)
			color(colorInvertedFixed)
			borderColor(borderColorProgressive)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorProgressiveHover).important()
				borderColor(borderColorProgressiveHover).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorProgressiveActive).important()
				borderColor(borderColorProgressiveActive).important()
			}

			pseudoClass(.focus) {
				borderColor(borderColorProgressiveFocus).important()
				boxShadow(boxShadowOutsetSmall, boxShadowColorProgressiveFocus).important()
			}

		// Progressive + Quiet
		case (.progressive, .quiet):
			backgroundColor(.transparent)
			color(colorProgressive)
			borderColor(.transparent)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorProgressiveSubtle).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorProgressiveSubtleHover).important()
				color(colorProgressiveActive).important()
			}

		// Destructive + Normal
		case (.destructive, .normal):
			backgroundColor(backgroundColorDestructiveSubtle)
			color(colorDestructive)
			borderColor(borderColorDestructive)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorDestructiveSubtleHover).important()
				borderColor(borderColorDestructiveHover).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorDestructiveSubtleActive).important()
				borderColor(borderColorDestructiveActive).important()
				color(colorDestructiveActive).important()
			}

			pseudoClass(.focus) {
				borderColor(borderColorDestructiveFocus).important()
				boxShadow(boxShadowOutsetSmall, boxShadowColorDestructiveFocus).important()
			}

		// Destructive + Primary
		case (.destructive, .primary):
			backgroundColor(backgroundColorDestructive)
			color(colorInvertedFixed)
			borderColor(borderColorDestructive)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorDestructiveHover).important()
				borderColor(borderColorDestructiveHover).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorDestructiveActive).important()
				borderColor(borderColorDestructiveActive).important()
			}

			pseudoClass(.focus) {
				borderColor(borderColorDestructiveFocus).important()
				boxShadow(boxShadowOutsetSmall, boxShadowColorDestructiveFocus).important()
			}

		// Destructive + Quiet
		case (.destructive, .quiet):
			backgroundColor(.transparent)
			color(colorDestructive)
			borderColor(.transparent)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorDestructiveSubtle).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorDestructiveSubtleHover).important()
				color(colorDestructiveActive).important()
			}
		}
	}
}

#endif
