#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct AlertView: HTML {
	let type: AlertType
	let inline: Bool
	let customIcon: String?
	let fadeIn: Bool
	let allowUserDismiss: Bool
	let dismissButtonLabel: String
	let autoDismiss: AutoDismiss
	let content: [HTML]
	let `class`: String

	public enum AlertType: Sendable {
		case notice
		case warning
		case error
		case success

		var value: String {
			switch self {
                case .notice: return "notice"
                case .warning: return "warning"
                case .error: return "error"
                case .success: return "success"
			}
		}
	}

	public enum AutoDismiss: Sendable {
		case disabled
		case `default` // 4000ms
		case custom(Int) // milliseconds
	}

	public init(
		type: AlertType = .notice,
		inline: Bool = false,
		customIcon: String? = nil,
		fadeIn: Bool = false,
		allowUserDismiss: Bool = false,
		dismissButtonLabel: String = "Close",
		autoDismiss: AutoDismiss = .disabled,
		class: String = "",
		@HTMLBuilder content: () -> [HTML]
	) {
		self.type = type
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
	private func alertViewCSS(_ type: AlertType, _ inline: Bool) -> [CSS] {
		display(.flex)
		boxSizing(.borderBox)

		if !inline {
			minHeight(px(64))
			padding(spacing12, spacing16)
			borderWidth(borderWidthBase)
			borderStyle(.solid)
			borderRadius(borderRadiusBase)

			switch type {
			case .notice:
				backgroundColor(backgroundColorNoticeSubtle)
				borderColor(borderColorNotice)
			case .warning:
				backgroundColor(backgroundColorWarningSubtle)
				borderColor(borderColorWarning)
			case .error:
				backgroundColor(backgroundColorErrorSubtle)
				borderColor(borderColorError)
			case .success:
				backgroundColor(backgroundColorSuccessSubtle)
				borderColor(borderColorSuccess)
			}
		} else {
			padding(0)
		}
	}

	@CSSBuilder
	private func alertIconCSS(_ type: AlertType) -> [CSS] {
		display(.flex)
		alignItems(.center)
		minWidth(sizeIconMedium)
		width(sizeIconMedium)
		height(sizeIconMedium)
		marginRight(spacing8)
		flexShrink(0)
		fontSize(sizeIconMedium)

		switch type {
		case .notice:
			color(colorNotice)
		case .warning:
			color(colorWarning)
		case .error:
			color(colorError)
		case .success:
			color(colorSuccess)
		}
	}

	@CSSBuilder
	private func alertContentCSS() -> [CSS] {
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
	private func alertFadeInCSS() -> [CSS] {
		animation("alert-fade-in", transitionDurationBase, transitionTimingFunctionSystem)
	}

	public func render(indent: Int = 0) -> String {
		let defaultIcon: String = {
			switch type {
			case .notice:
				return "i"
			case .warning:
				return "!"
			case .error:
				return "x"
			case .success:
				return "+"
			}
		}()

		let displayIcon = customIcon ?? defaultIcon
		let shouldShowIcon = type != .notice || customIcon != nil

		let ariaLive: String = {
			switch type {
			case .error: return "assertive"
			default: return "polite"
			}
		}()

		let role: String? = type == .error ? "alert" : nil

		let autoDismissValue: Int? = {
			switch autoDismiss {
			case .disabled:
				return nil
			case .default:
				return 4000
			case .custom(let ms):
				return type == .error ? nil : ms
			}
		}()

		let alertClasses: String = {
			let base = "alert-view alert-\(type.value)"
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
					alertIconCSS(type)
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
				alertViewCSS(type, inline)
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
	/// Alert type for dynamic alerts
	public enum AlertType: Sendable {
		case notice
		case warning
		case error
		case success
	}

	/// Show a dynamic alert without page reload
	public static func show(
		_ text: String,
		type: AlertType = .notice,
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
			case .notice:
				return (backgroundColorNoticeSubtle, borderColorNotice, colorNotice)
			case .warning:
				return (backgroundColorWarningSubtle, borderColorWarning, colorWarning)
			case .error:
				return (backgroundColorErrorSubtle, borderColorError, colorError)
			case .success:
				return (backgroundColorSuccessSubtle, borderColorSuccess, colorSuccess)
			}
		}()

		let defaultIcon: String = {
			switch type {
			case .notice:
				return "i"
			case .warning:
				return "!"
			case .error:
				return "x"
			case .success:
				return "+"
			}
		}()
		
		let displayIcon: String
		if let custom = customIcon {
			displayIcon = custom
		} else {
			displayIcon = defaultIcon
		}
		let shouldShowIcon = type != .notice || customIcon != nil
		
		let ariaLive: ARIALive
		switch type {
			case .error:
				ariaLive = .assertive
			default:
				ariaLive = .polite
		}

		// Create alert element
		let alertEl = document.createElement(.div)
		let alertClass: String
		switch type {
			case .notice:
				alertClass = "alert-view alert-notice alert-fade-in"
			case .warning:
				alertClass = "alert-view alert-warning alert-fade-in"
			case .error:
				alertClass = "alert-view alert-error alert-fade-in"
			case .success:
				alertClass = "alert-view alert-success alert-fade-in"
		}
		alertEl.className = alertClass
		alertEl.setAttribute(.ariaLive, ariaLive)
		if type == .error {
			alertEl.setAttribute(.role, .alert)
		}
		
		alertEl.style.display(.flex)
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
			dismissBtn.innerHTML = "x"
			dismissBtn.setAttribute(.type, .button)
			dismissBtn.setAttribute(.ariaLabel, "Close")
			dismissBtn.style.display(.flex)
			dismissBtn.style.alignItems(.flexStart)
			dismissBtn.style.minWidth(sizeIconMedium)
			dismissBtn.style.width(sizeIconMedium)
			dismissBtn.style.height(sizeIconMedium)
			dismissBtn.style.marginLeft(spacing8)
			dismissBtn.style.padding(px(0))
			dismissBtn.style.border(borderTransparent)
			dismissBtn.style.backgroundColor(backgroundColorTransparent)
			dismissBtn.style.color(colorSubtle)
			dismissBtn.style.fontSize(sizeIconMedium)
			dismissBtn.style.cursor(cursorBaseHover)
			dismissBtn.style.borderRadius(borderRadiusBase)

			dismissBtn.style.transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

            dismissBtn.style.flexShrink(0)
            
			_ = dismissBtn.on(.click) { _ in
				dismissAlert(alertEl, onDismiss: onDismiss, userInitiated: true)
			}

			alertEl.appendChild(dismissBtn)
            
		}
		// Add to container
		alertContainer.appendChild(alertEl)

		// Auto-dismiss
		if autoDismiss && type != .error {
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
		show(text, type: .notice, container: container, onDismiss: onDismiss)
	}

	public static func showWarning(_ text: String, container: Element? = nil, onDismiss: (@Sendable () -> Void)? = nil) {
		show(text, type: .warning, container: container, onDismiss: onDismiss)
	}

	public static func showError(_ text: String, container: Element? = nil, onDismiss: (@Sendable () -> Void)? = nil) {
		show(text, type: .error, container: container, onDismiss: onDismiss)
	}

	public static func showSuccess(_ text: String, container: Element? = nil, onDismiss: (@Sendable () -> Void)? = nil) {
		show(text, type: .success, autoDismiss: true, container: container, onDismiss: onDismiss)
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

		_ = button.on(.click) { [self] _ in
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
