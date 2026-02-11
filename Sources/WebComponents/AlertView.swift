#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct AlertView: HTMLProtocol {
	let alertColor: AlertColor
	let inline: Bool
	let customIcon: String?
	let fadeIn: Bool
	let allowUserDismiss: Bool
	let dismissButtonLabel: String
	let autoDismiss: AutoDismiss
	let content: [HTMLProtocol]
	let `class`: String

	/// Apple HIG color for the alert
	public enum AlertColor: String, Sendable {
		case gray
		case orange
		case red
		case green

		// Legacy aliases
		public static let notice = AlertColor.gray
		public static let warning = AlertColor.orange
		public static let error = AlertColor.red
		public static let success = AlertColor.green
	}

	/// Legacy alias
	public typealias AlertType = AlertColor

	public enum AutoDismiss: Sendable {
		case disabled
		case `default` // 4000ms
		case custom(Int) // milliseconds
	}

	/// Legacy init
	public init(
		type: AlertColor,
		inline: Bool = false,
		customIcon: String? = nil,
		fadeIn: Bool = false,
		allowUserDismiss: Bool = false,
		dismissButtonLabel: String = "Close",
		autoDismiss: AutoDismiss = .disabled,
		class: String = "",
		@HTMLBuilder content: () -> [HTMLProtocol]
	) {
		self.alertColor = type
		self.inline = inline
		self.customIcon = customIcon
		self.fadeIn = fadeIn
		self.allowUserDismiss = allowUserDismiss
		self.dismissButtonLabel = dismissButtonLabel
		self.autoDismiss = autoDismiss
		self.content = content()
		self.`class` = `class`
	}

	public init(
		color: AlertColor = .gray,
		inline: Bool = false,
		customIcon: String? = nil,
		fadeIn: Bool = false,
		allowUserDismiss: Bool = false,
		dismissButtonLabel: String = "Close",
		autoDismiss: AutoDismiss = .disabled,
		class: String = "",
		@HTMLBuilder content: () -> [HTMLProtocol]
	) {
		self.alertColor = color
		self.inline = inline
		self.customIcon = customIcon
		self.fadeIn = fadeIn
		self.allowUserDismiss = allowUserDismiss
		self.dismissButtonLabel = dismissButtonLabel
		self.autoDismiss = autoDismiss
		self.content = content()
		self.`class` = `class`
	}

	@CSSBuilder
	private func alertViewCSS(_ alertColor: AlertColor, _ inline: Bool) -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		gap(spacing8)
		boxSizing(.borderBox)

		if !inline {
			minHeight(px(64))
			padding(spacing12, spacing16)
			borderWidth(borderWidthBase)
			borderStyle(.solid)
			borderRadius(borderRadiusBase)

			switch alertColor {
			case .gray:
				backgroundColor(backgroundColorGraySubtle)
				borderColor(borderColorGray)
			case .orange:
				backgroundColor(backgroundColorOrangeSubtle)
				borderColor(borderColorOrange)
			case .red:
				backgroundColor(backgroundColorRedSubtle)
				borderColor(borderColorRed)
			case .green:
				backgroundColor(backgroundColorGreenSubtle)
				borderColor(borderColorGreen)
			}
		} else {
			padding(0)
		}
	}

	@CSSBuilder
	private func alertIconCSS(_ alertColor: AlertColor) -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		minWidth(sizeIconMedium)
		width(sizeIconMedium)
		height(sizeIconMedium)
		flexShrink(0)
		fontSize(sizeIconMedium)

		switch alertColor {
		case .gray:
			color(colorGray)
		case .orange:
			color(colorOrange)
		case .red:
			color(colorRed)
		case .green:
			color(colorGreen)
		}
	}

	@CSSBuilder
	private func alertContentCSS() -> [CSSProtocol] {
		display(.flex)
		flexDirection(.column)
		flexGrow(1)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightNormal)
		lineHeight(lineHeightSmall22)
		color(colorBase)
		justifyContent(.center)
	}

	@CSSBuilder
	private func alertFadeInCSS() -> [CSSProtocol] {
		animation("alert-fade-in", transitionDurationBase, transitionTimingFunctionSystem)
	}

	public func render(indent: Int = 0) -> String {
		let defaultIcon: String = {
			switch alertColor {
			case .gray:
				return "ℹ"
			case .orange:
				return "⚠"
			case .red:
				return "✗"
			case .green:
				return "✓"
			}
		}()

		let displayIcon = customIcon ?? defaultIcon
		let shouldShowIcon = alertColor != .gray || customIcon != nil

		let ariaLive: String = {
			switch alertColor {
			case .red: return "assertive"
			default: return "polite"
			}
		}()

		let role: String? = alertColor == .red ? "alert" : nil

		let autoDismissValue: Int? = {
			switch autoDismiss {
			case .disabled:
				return nil
			case .default:
				return 4000
			case .custom(let ms):
				return alertColor == .red ? nil : ms
			}
		}()

		let alertClasses: String = {
			let base = "alert-view alert-\(alertColor.rawValue)"
			let inlinePart = inline ? " alert-inline" : ""
			let fadePart = fadeIn ? " alert-fade-in" : ""
			let classPart = `class`.isEmpty ? "" : " \(`class`)"
			return "\(base)\(inlinePart)\(fadePart)\(classPart)"
		}()

		var alert = div {
			if shouldShowIcon {
				span {
					displayIcon
				}
				.class("alert-icon")
				.ariaHidden(true)
				.style {
					alertIconCSS(alertColor)
				}
			}

			div {
				content
			}
			.class("alert-content")
			.style {
				alertContentCSS()
			}

			if allowUserDismiss {
				CloseButtonView(ariaLabel: dismissButtonLabel, class: "alert-dismiss")
			}
		}
		.class(alertClasses)
		.ariaLive(ariaLive)

		if let role = role {
			alert = alert.role(role)
		}

		if let autoDismissValue = autoDismissValue {
			alert = alert.data("auto-dismiss", "\(autoDismissValue)")
		}

		return alert
			.style {
				alertViewCSS(alertColor, inline)
				if fadeIn {
					alertFadeInCSS()
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

// Helper for safe string concatenation
private func concat(_ parts: String...) -> String {
    var buffer: [UInt8] = []
    for part in parts {
        buffer.append(contentsOf: part.utf8)
    }
    return String(decoding: buffer, as: UTF8.self)
}

// Helper for parsing Int from String safely
private func localParseInt(_ str: String) -> Int? {
	var result = 0
	var isNegative = false
	var hasDigits = false
	for byte in str.utf8 {
		if byte == 45 { // '-'
			if hasDigits { return nil }
			isNegative = true
		} else if byte >= 48 && byte <= 57 { // 0-9
			result = result * 10 + Int(byte - 48)
			hasDigits = true
		} else {
			return nil
		}
	}
	return hasDigits ? (isNegative ? -result : result) : nil
}

/// Dynamic alert creation functions
public enum AlertAPI {
	/// Alert color for dynamic alerts
	public enum AlertColor: Sendable {
		case gray
		case orange
		case red
		case green

		// Legacy aliases
		public static let notice = AlertColor.gray
		public static let warning = AlertColor.orange
		public static let error = AlertColor.red
		public static let success = AlertColor.green
	}

	/// Legacy alias
	public typealias AlertType = AlertColor

	/// Show a dynamic alert without page reload
	public static func show(
		_ text: String,
		type: AlertColor = .gray,
		inline: Bool = false,
		customIcon: String? = nil,
		allowUserDismiss: Bool = true,
		autoDismiss: Bool = false,
		autoDismissTime: Int = 4000,
		container: Element? = nil,
		onDismiss: (@Sendable () -> Void)? = nil
	) {

		let alertContainer: Element

		if let providedContainer = container {
			alertContainer = providedContainer
		} else if let pageAlerts = document.querySelector(".page-alerts") {
			alertContainer = pageAlerts
		} else {
			var existingContainer = document.querySelector(".alert-container")
			if existingContainer == nil {
				let newContainer = document.createElement(.div)
				newContainer.className = "alert-container"
				newContainer.style.position(.fixed)
				newContainer.style.top(px(80))
				newContainer.style.left(perc(50))
				newContainer.style.transform(translateX(perc(-50)))
				newContainer.style.zIndex(zIndexTooltip)
				newContainer.style.display(.flex)
				newContainer.style.flexDirection(.column)
				newContainer.style.gap(spacing12)
				newContainer.style.maxWidth(px(600))
				newContainer.style.width(calc(perc(100) - px(48)))
				newContainer.style.pointerEvents(.none)
				document.body.appendChild(newContainer)
				existingContainer = newContainer
			}
			guard let c = existingContainer else { return }
			alertContainer = c
		}

		let (bgColor, borderColor, iconColor): (CSSColor, CSSColor, CSSColor) = {
			switch type {
			case .gray:
				return (backgroundColorGraySubtle, borderColorGray, colorGray)
			case .orange:
				return (backgroundColorOrangeSubtle, borderColorOrange, colorOrange)
			case .red:
				return (backgroundColorRedSubtle, borderColorRed, colorRed)
			case .green:
				return (backgroundColorGreenSubtle, borderColorGreen, colorGreen)
			}
		}()

		let defaultIcon: String = {
			switch type {
			case .gray:
				return "ℹ"
			case .orange:
				return "⚠"
			case .red:
				return "✗"
			case .green:
				return "✓"
			}
		}()

		let displayIcon: String
		if let custom = customIcon {
			displayIcon = custom
		} else {
			displayIcon = defaultIcon
		}
		let shouldShowIcon = type != .gray || customIcon != nil

		let ariaLive: ARIALive
		switch type {
			case .red:
				ariaLive = .assertive
			default:
				ariaLive = .polite
		}

		// Create alert element
		let alertEl = document.createElement(.div)
		let alertClass: String
		switch type {
			case .gray:
				alertClass = "alert-view alert-gray alert-fade-in"
			case .orange:
				alertClass = "alert-view alert-orange alert-fade-in"
			case .red:
				alertClass = "alert-view alert-red alert-fade-in"
			case .green:
				alertClass = "alert-view alert-green alert-fade-in"
		}
		alertEl.className = alertClass
		alertEl.setAttribute(.ariaLive, ariaLive)
		if type == .red {
			alertEl.setAttribute(.role, .alert)
		}
		
		alertEl.style.display(.flex)
		alertEl.style.alignItems(.center)
		alertEl.style.boxSizing(.borderBox)
		alertEl.style.pointerEvents(.auto)
		alertEl.style.animation(("alert-fade-in", s(0.3), .easeOut))

		if !inline {
			alertEl.style.minHeight(px(64))
			alertEl.style.padding(spacing12, spacing16)
			alertEl.style.borderWidth(borderWidthBase)
			alertEl.style.borderStyle(.solid)
			alertEl.style.borderRadius(borderRadiusBase)
			alertEl.style.backgroundColor(bgColor)
			alertEl.style.borderColor(borderColor)
			alertEl.style.boxShadow((0, px(2), px(8), rgba(0, 0, 0, 0.1)))
		} else {
			alertEl.style.padding(px(0))
		}

		// Icon
		if shouldShowIcon {
			let icon = document.createElement(.span)
			icon.className = "alert-icon"
			icon.innerHTML = displayIcon
			icon.setAttribute(.ariaHidden, true)
			icon.style.display(.flex)
			icon.style.alignItems(.center)
			icon.style.minWidth(sizeIconMedium)
			icon.style.width(sizeIconMedium)
			icon.style.height(sizeIconMedium)
			icon.style.marginRight(spacing8)
			icon.style.flexShrink(0)
			icon.style.fontSize(sizeIconMedium)
			icon.style.color(iconColor)
			alertEl.appendChild(icon)
		}

		// Content
		let content = document.createElement(.div)
		content.className = "alert-content"
		content.innerHTML = text
		content.style.display(.flex)
		content.style.flexDirection(.column)
		content.style.flexGrow(1)
		content.style.fontFamily(typographyFontSans)
		content.style.fontSize(fontSizeMedium16)
		content.style.fontWeight(fontWeightNormal)
		content.style.lineHeight(lineHeightSmall22)
		content.style.color(colorBase)
		alertEl.appendChild(content)

		// Dismiss button
		if allowUserDismiss {
			let dismissBtn = document.createElement(.button)
			dismissBtn.className = "alert-dismiss"
			// Use proper SVGProtocol close icon
			dismissBtn.innerHTML = "<svg width=\"20\" height=\"20\" viewBox=\"0 0 20 20\" xmlns=\"http://www.w3.org/2000/svg\" fill=\"currentColor\"><path d=\"M4.34 2.93l12.73 12.73-1.41 1.41L2.93 4.35Z\"/><path d=\"M17.07 4.34L4.34 17.07l-1.41-1.41L15.66 2.93Z\"/></svg>"
			let buttonType: HTMLButton.`Type` = .button
			dismissBtn.setAttribute(.type, buttonType)
			dismissBtn.setAttribute(.ariaLabel, "Close")
			dismissBtn.style.display(.flex)
			dismissBtn.style.alignItems(.center)
			dismissBtn.style.justifyContent(.center)
			dismissBtn.style.minWidth(sizeIconMedium)
			dismissBtn.style.width(sizeIconMedium)
			dismissBtn.style.height(sizeIconMedium)
			dismissBtn.style.marginLeft(spacing8)
			dismissBtn.style.padding(px(0))
			dismissBtn.style.border(borderTransparent)
			dismissBtn.style.backgroundColor(backgroundColorTransparent)
			dismissBtn.style.color(colorSubtle)
			dismissBtn.style.cursor(cursorBaseHover)
			dismissBtn.style.borderRadius(borderRadiusBase)
			dismissBtn.style.transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
			dismissBtn.style.flexShrink(0)

			_ = dismissBtn.addEventListener(.click) { _ in
				dismissAlert(alertEl, onDismiss: onDismiss, userInitiated: true)
			}

			alertEl.appendChild(dismissBtn)
		}
		// Add to container
		alertContainer.appendChild(alertEl)

		// Auto-dismiss
		if autoDismiss && type != .red {
			_ = setTimeout(autoDismissTime) {
				dismissAlert(alertEl, onDismiss: onDismiss, userInitiated: false)
			}
		}
	}

	private static func dismissAlert(_ element: Element, onDismiss: (@Sendable () -> Void)?, userInitiated: Bool) {
		element.style.animation(("alert-fade-out", s(0.3), .easeOut))

		_ = setTimeout(300) {
			element.remove()
			onDismiss?()

			let eventType: String
			if userInitiated {
				eventType = "user_dismissed"
			} else {
				eventType = "auto_dismissed"
			}
			let event = CustomEvent(type: eventType, detail: "")
			element.dispatchEvent(event)
		}
	}

	/// Convenience methods
	public static func showNotice(_ text: String, container: Element? = nil, onDismiss: (@Sendable () -> Void)? = nil) {
		show(text, type: .gray, container: container, onDismiss: onDismiss)
	}

	public static func showWarning(_ text: String, container: Element? = nil, onDismiss: (@Sendable () -> Void)? = nil) {
		show(text, type: .orange, container: container, onDismiss: onDismiss)
	}

	public static func showError(_ text: String, container: Element? = nil, onDismiss: (@Sendable () -> Void)? = nil) {
		show(text, type: .red, container: container, onDismiss: onDismiss)
	}

	public static func showSuccess(_ text: String, container: Element? = nil, onDismiss: (@Sendable () -> Void)? = nil) {
		show(text, type: .green, autoDismiss: true, container: container, onDismiss: onDismiss)
	}
}

private class AlertInstance: @unchecked Sendable {
	private var alertElement: Element
	private var dismissButton: Element?
	private var autoDismissTimer: Int32?

	init(alert: Element) {
		self.alertElement = alert
		self.dismissButton = alert.querySelector(".alert-dismiss")

		bindEvents()
		setupAutoDismiss()
	}

	private func bindEvents() {
		guard let button = dismissButton else { return }

		_ = button.addEventListener(.click) { [self] _ in
			self.dismissAlert(userInitiated: true)
		}
	}

	private func setupAutoDismiss() {
		guard let autoDismissAttr = alertElement.getAttribute(data("auto-dismiss")),
			let ms = localParseInt(autoDismissAttr) else {
			return
		}

		autoDismissTimer = setTimeout(ms) { [self] in
		self.dismissAlert(userInitiated: false)
		}
	}

	private func dismissAlert(userInitiated: Bool) {
		if let timer = autoDismissTimer {
			clearTimeout(timer)
			autoDismissTimer = nil
		}

		alertElement.style.animation(("alert-fade-out", s(0.3), .easeOut))

		_ = setTimeout(300) { [self] in
			self.alertElement.remove()

			let eventType: String
			if userInitiated {
				eventType = "user_dismissed"
			} else {
				eventType = "auto_dismissed"
			}
			let event = CustomEvent(type: eventType, detail: "")
			self.alertElement.dispatchEvent(event)
		}
	}
}

/// Hydration for server-rendered alerts
public class AlertHydration: @unchecked Sendable {
	private var instances: [AlertInstance] = []

	public init() {
		hydrateAllAlerts()
	}

	private func hydrateAllAlerts() {
		let allAlerts = document.querySelectorAll(".alert-view")

		for alert in allAlerts {
			let instance = AlertInstance(alert: alert)
			instances.append(instance)
		}
	}
}

#endif
