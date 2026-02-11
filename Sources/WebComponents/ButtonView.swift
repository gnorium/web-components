#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Button — triggers an action when the user clicks or taps on it.
public struct ButtonView: HTMLProtocol {
	let label: String
	let buttonColor: ButtonColor
	let weight: ButtonWeight
	let size: ButtonSize
	let icon: (any HTMLProtocol)?
	let iconOnly: Bool
	let disabled: Bool
	let ariaLabel: String?
	let url: String?
	let onClick: String?
	let type: ButtonType
	let fullWidth: Bool
	var `class`: String
	let labelFontWeight: CSSFontWeight
	let contentJustifyContent: CSSJustifyContent

	/// Button type attribute
	public enum ButtonType: String, Sendable {
		case button
		case submit
		case reset
	}

	/// Button color — Apple HIG color for the button's action identity
	public enum ButtonColor: String, Sendable {
		/// Neutral buttons for actions that are neutral or secondary in importance
		case gray
		/// Blue buttons for primary/progressive actions
		case blue
		/// Red buttons for destructive/removal actions
		case red
	}

	/// Button weight (visual prominence)
	public enum ButtonWeight: String, Sendable {
		/// Solid buttons signal the main action — filled background, inverted text
		case solid
		/// Subtle buttons are the default — light background, colored text, border
		case subtle
		/// Quiet buttons — transparent, no border, hover shows subtle background
		case quiet
		/// Plain buttons — transparent, no background change on hover
		case plain
	}

	/// Button sizes
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
    
	public init(
		label: String,
		buttonColor: ButtonColor = .gray,
		weight: ButtonWeight = .subtle,
		size: ButtonSize = .medium,
		disabled: Bool = false,
		url: String? = nil,
		type: ButtonType = .button,
		ariaLabel: String? = nil,
		onClick: String? = nil,
		fullWidth: Bool = false,
		class: String = "",
		labelFontWeight: CSSFontWeight = fontWeightBold,
		contentJustifyContent: CSSJustifyContent = .center
	) {
		self.label = label
		self.buttonColor = buttonColor
		self.weight = weight
		self.size = size
		self.icon = nil
		self.iconOnly = false
		self.disabled = disabled
		self.ariaLabel = ariaLabel
		self.url = url
		self.onClick = onClick
		self.type = type
		self.fullWidth = fullWidth
		self.class = `class`
		self.labelFontWeight = labelFontWeight
		self.contentJustifyContent = contentJustifyContent
	}

	public init(
		label: String,
		icon: any HTMLProtocol,
		buttonColor: ButtonColor = .gray,
		weight: ButtonWeight = .subtle,
		size: ButtonSize = .medium,
		disabled: Bool = false,
		url: String? = nil,
		type: ButtonType = .button,
		ariaLabel: String? = nil,
		onClick: String? = nil,
		fullWidth: Bool = false,
		class: String = "",
		labelFontWeight: CSSFontWeight = fontWeightBold,
		contentJustifyContent: CSSJustifyContent = .center
	) {
		self.label = label
		self.buttonColor = buttonColor
		self.weight = weight
		self.size = size
		self.icon = icon
		self.iconOnly = false
		self.disabled = disabled
		self.ariaLabel = ariaLabel
		self.url = url
		self.onClick = onClick
		self.type = type
		self.fullWidth = fullWidth
		self.class = `class`
		self.labelFontWeight = labelFontWeight
		self.contentJustifyContent = contentJustifyContent
	}

	/// Create an icon-only button
	/// WARNING: Icon-only buttons require aria-label for accessibility
	public init(
		icon: any HTMLProtocol,
		buttonColor: ButtonColor = .gray,
		weight: ButtonWeight = .subtle,
		size: ButtonSize = .medium,
		disabled: Bool = false,
		url: String? = nil,
		type: ButtonType = .button,
		ariaLabel: String,
		onClick: String? = nil,
		fullWidth: Bool = false,
		class: String = "",
		labelFontWeight: CSSFontWeight = fontWeightBold,
		contentJustifyContent: CSSJustifyContent = .center
	) {
		self.label = ""
		self.buttonColor = buttonColor
		self.weight = weight
		self.size = size
		self.icon = icon
		self.iconOnly = true
		self.disabled = disabled
		self.ariaLabel = ariaLabel
		self.url = url
		self.onClick = onClick
		self.type = type
		self.fullWidth = fullWidth
		self.class = `class`
		self.labelFontWeight = labelFontWeight
		self.contentJustifyContent = contentJustifyContent
	}

	/// Create a button with custom content
	public init(
        label: String = "",
		buttonColor: ButtonColor = .gray,
		weight: ButtonWeight = .subtle,
		size: ButtonSize = .medium,
		disabled: Bool = false,
		url: String? = nil,
		type: ButtonType = .button,
		ariaLabel: String? = nil,
		onClick: String? = nil,
		fullWidth: Bool = false,
		class: String = "",
		labelFontWeight: CSSFontWeight = fontWeightBold,
		contentJustifyContent: CSSJustifyContent = .center,
		@HTMLBuilder content: () -> [any HTMLProtocol]
	) {
		self.label = label
		self.buttonColor = buttonColor
		self.weight = weight
		self.size = size
		self.icon = content()
		self.iconOnly = false // Custom content is treated as the full body
		self.disabled = disabled
		self.ariaLabel = ariaLabel
		self.url = url
		self.onClick = onClick
		self.type = type
		self.fullWidth = fullWidth
		self.class = `class`
		self.labelFontWeight = labelFontWeight
		self.contentJustifyContent = contentJustifyContent
	}

	public func render(indent: Int = 0) -> String {
		let baseClasses = "button-view button-color-\(buttonColor.rawValue) button-weight-\(weight.rawValue) button-size-\(size.rawValue)\(iconOnly ? " button-icon-only" : "")"
		let fullClass = `class`.isEmpty ? baseClasses : "\(baseClasses) \(`class`)"

		@HTMLBuilder
		func renderContent() -> [any HTMLProtocol] {
			if let icon = icon {
				if label.isEmpty && iconOnly {
					span { icon }
						.class("button-icon")
						.ariaHidden(true)
						.style {
							buttonIconCSS()
						}
				} else {
					// Either custom content or icon+label
					icon
				}
			}

			if !label.isEmpty {
				span { label }
					.class("button-label")
					.style {
						padding(0)
						overflow(.hidden)
						whiteSpace(.nowrap)
						borderWidth(0)
					}
			}
		}

		if let url = url {
			var aBtn = a { renderContent() }
				.href(url)
				.class(fullClass)
				.data("color", buttonColor.rawValue)
				.data("weight", weight.rawValue)
				.data("size", size.rawValue)
				.style {
					buttonViewCSS()
				}

			if disabled {
				aBtn = aBtn.ariaDisabled(true).class("disabled")
			}

			if let ariaLbl = effectiveAriaLabel {
				aBtn = aBtn.ariaLabel(ariaLbl)
			}

			if let click = onClick {
				aBtn = aBtn.onclick(click)
			}

			return aBtn.render(indent: indent)
		} else {
			var bBtn = button { renderContent() }
				.type(type == .submit ? .submit : type == .reset ? .reset : .button)
				.class(fullClass)
				.data("color", buttonColor.rawValue)
				.data("weight", weight.rawValue)
				.data("size", size.rawValue)
				.disabled(disabled)
				.style {
					buttonViewCSS()
				}

			if let ariaLbl = effectiveAriaLabel {
				bBtn = bBtn.ariaLabel(ariaLbl)
			}

			if let click = onClick {
				bBtn = bBtn.onclick(click)
			}

			return bBtn.render(indent: indent)
		}
	}

	@CSSBuilder
	private func buttonViewCSS() -> [CSSProtocol] {
		// Base button styles
		if iconOnly {
			display(.flex)
			justifyContent(.center)
		} else {
			if fullWidth {
				display(.flex)
			} else {
				display(.inlineFlex)
			}
		}
		alignItems(.center)
		justifyContent(contentJustifyContent)
		gap(spacingHorizontalButton)
		fontFamily(fontFamilyBase)
		fontSize(fontSizeMedium16)
		fontWeight(labelFontWeight)
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
			media(maxWidth(maxWidthBreakpointMobile)) {
				width(perc(100)).important()
				display(.flex).important()
			}
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

		// Color + Weight combinations
		applyColorWeightCSS()

		// Focus state
		pseudoClass(.focus) {
			outline(borderWidthBase, .solid, borderColorTransparent).important()
		}

		// Disabled state
		pseudoClass(.disabled) {
			color(colorInvertedFixed).important()
			if weight == .quiet {
				backgroundColor(.transparent).important()
				borderColor(.transparent).important()
			} else {
				backgroundColor(backgroundColorDisabled).important()
				borderColor(borderColorDisabled).important()
			}
			cursor(.default).important()
			pointerEvents(.none).important()
		}

		// Icon hover color when button is disabled
		pseudoClass(.disabled) {
			descendant(".icon-view") {
				pseudoClass(.hover) {
					color(colorInvertedFixed).important()
				}
			}
		}
	}

	@CSSBuilder
	private func buttonIconCSS() -> [CSSProtocol] {
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

	private var effectiveAriaLabel: String? {
		if let ariaLabel = ariaLabel {
			return ariaLabel
		} else if !label.isEmpty {
			return label
		} else {
			return nil
		}
	}
    
	@CSSBuilder
	private func applyColorWeightCSS() -> [CSSProtocol] {
		switch (buttonColor, weight) {
		// Gray + Subtle
		case (.gray, .subtle):
			backgroundColor(backgroundColorBase)
			color(colorBase)
			borderColor(borderColorBase)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorInteractive).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorInteractiveActive).important()
				color(colorEmphasized).important()
				borderColor(borderColorBase).important()
			}

		// Gray + Solid
		case (.gray, .solid):
			backgroundColor(backgroundColorInteractive)
			color(colorBase)
			borderColor(borderColorBase)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorInteractiveHover).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorInteractiveActive).important()
				color(colorEmphasized).important()
				borderColor(borderColorBase).important()
			}

		// Gray + Quiet
		case (.gray, .quiet):
			backgroundColor(.transparent)
			color(colorBase)
			borderColor(.transparent)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorInteractiveSubtle).important()
				borderColor(.transparent).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorInteractiveSubtleActive).important()
				color(colorEmphasized).important()
				borderColor(.transparent).important()
			}

			pseudoClass(.focus) {
				borderColor(.transparent).important()
				boxShadow(.none).important()
			}

		// Gray + Plain
        case (.gray, .plain):
            backgroundColor(.transparent)
            color(colorBase)
            borderColor(.transparent)

            pseudoClass(.hover, not(.disabled)) {
                backgroundColor(.transparent).important()
                color(colorBase).important()
                borderColor(.transparent).important()
            }

            pseudoClass(.active, not(.disabled)) {
                backgroundColor(.transparent).important()
                color(colorEmphasized).important()
                borderColor(.transparent).important()
            }

            pseudoClass(.focus) {
                borderColor(.transparent).important()
                boxShadow(.none).important()
            }

		// Blue + Subtle
		case (.blue, .subtle):
			backgroundColor(backgroundColorBlueSubtle)
			color(colorBlue)
			borderColor(borderColorBlue)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorBlueSubtleHover).important()
				borderColor(borderColorBlueHover).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorBlueSubtleActive).important()
				borderColor(borderColorBlueActive).important()
				color(colorBlueActive).important()
			}

			pseudoClass(.focus) {
				borderColor(borderColorBlueFocus).important()
				boxShadow(boxShadowOutsetSmall, boxShadowColorBlueFocus).important()
			}

		// Blue + Solid
		case (.blue, .solid):
			backgroundColor(backgroundColorBlue)
			color(colorInvertedFixed)
			borderColor(borderColorBlue)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorBlueHover).important()
				borderColor(borderColorBlueHover).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorBlueActive).important()
				borderColor(borderColorBlueActive).important()
			}

			pseudoClass(.focus) {
				borderColor(borderColorBlueFocus).important()
				boxShadow(boxShadowOutsetSmall, boxShadowColorBlueFocus).important()
			}

		// Blue + Quiet
		case (.blue, .quiet):
			backgroundColor(.transparent)
			color(colorBlue)
			borderColor(.transparent)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorBlueSubtle).important()
				borderColor(.transparent).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorBlueSubtleHover).important()
				color(colorBlueActive).important()
				borderColor(.transparent).important()
			}

			pseudoClass(.focus) {
				borderColor(.transparent).important()
				boxShadow(.none).important()
			}

		// Blue + Plain
        case (.blue, .plain):
            backgroundColor(.transparent)
            color(colorBlue)
            borderColor(.transparent)

            pseudoClass(.hover, not(.disabled)) {
                backgroundColor(.transparent).important()
                color(colorBlueHover).important()
                borderColor(.transparent).important()
            }

            pseudoClass(.active, not(.disabled)) {
                backgroundColor(.transparent).important()
                color(colorBlueActive).important()
                borderColor(.transparent).important()
            }

            pseudoClass(.focus) {
                borderColor(.transparent).important()
                boxShadow(.none).important()
            }

		// Red + Subtle
		case (.red, .subtle):
			backgroundColor(backgroundColorRedSubtle)
			color(colorRed)
			borderColor(borderColorRed)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorRedSubtleHover).important()
				borderColor(borderColorRedHover).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorRedSubtleActive).important()
				borderColor(borderColorRedActive).important()
				color(colorRedActive).important()
			}

			pseudoClass(.focus) {
				borderColor(borderColorRedFocus).important()
				boxShadow(boxShadowOutsetSmall, boxShadowColorRedFocus).important()
			}

		// Red + Solid
		case (.red, .solid):
			backgroundColor(backgroundColorRed)
			color(colorInvertedFixed)
			borderColor(borderColorRed)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorRedHover).important()
				borderColor(borderColorRedHover).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorRedActive).important()
				borderColor(borderColorRedActive).important()
			}

			pseudoClass(.focus) {
				borderColor(borderColorRedFocus).important()
				boxShadow(boxShadowOutsetSmall, boxShadowColorRedFocus).important()
			}

		// Red + Quiet
		case (.red, .quiet):
			backgroundColor(.transparent)
			color(colorRed)
			borderColor(.transparent)

			pseudoClass(.hover, not(.disabled)) {
				backgroundColor(backgroundColorRedSubtle).important()
				borderColor(.transparent).important()
			}

			pseudoClass(.active, not(.disabled)) {
				backgroundColor(backgroundColorRedSubtleHover).important()
				color(colorRedActive).important()
				borderColor(.transparent).important()
			}

			pseudoClass(.focus) {
				borderColor(.transparent).important()
				boxShadow(.none).important()
			}

		// Red + Plain
        case (.red, .plain):
            backgroundColor(.transparent)
            color(colorRed)
            borderColor(.transparent)

            pseudoClass(.hover, not(.disabled)) {
                backgroundColor(.transparent).important()
                color(colorRedHover).important()
                borderColor(.transparent).important()
            }

            pseudoClass(.active, not(.disabled)) {
                backgroundColor(.transparent).important()
                color(colorRedActive).important()
                borderColor(.transparent).important()
            }

            pseudoClass(.focus) {
                borderColor(.transparent).important()
                boxShadow(.none).important()
            }
		}
	}
}

#endif
