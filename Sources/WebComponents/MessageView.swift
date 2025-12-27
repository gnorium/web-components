#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Message component following Wikimedia Codex design system specification
/// A Message provides system feedback for users.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/message.html
public struct MessageView: HTML {
	let type: MessageType
	let inline: Bool
	let customIcon: String?
	let fadeIn: Bool
	let allowUserDismiss: Bool
	let dismissButtonLabel: String
	let autoDismiss: AutoDismiss
	let content: [HTML]
	let `class`: String

	public enum MessageType: Sendable {
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
		type: MessageType = .notice,
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
	private func messageViewCSS(_ type: MessageType, _ inline: Bool) -> [CSS] {
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
	private func messageIconCSS(_ type: MessageType) -> [CSS] {
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
	private func messageContentCSS() -> [CSS] {
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
	private func messageDismissCSS() -> [CSS] {
		display(.flex)
		alignItems(.flexStart)
		minWidth(sizeIconMedium)
		width(sizeIconMedium)
		height(sizeIconMedium)
		marginLeft(spacing8)
		padding(0)
		border(.none)
		backgroundColor(.transparent)
		color(colorSubtle)
		fontSize(sizeIconMedium)
		cursor(cursorBaseHover)
		borderRadius(borderRadiusBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		flexShrink(0)
		justifyContent(.center)
		
		pseudoClass(.hover) {
			backgroundColor(backgroundColorInteractiveSubtleHover).important()
		}

		pseudoClass(.active) {
			backgroundColor(backgroundColorInteractiveSubtleActive).important()
		}

		pseudoClass(.focus) {
			outline(borderWidthThick, .solid, borderColorProgressive).important()
			outlineOffset(px(1)).important()
		}
	}

	@CSSBuilder
	private func messageFadeInCSS() -> [CSS] {
		animation("message-fade-in", transitionDurationBase, transitionTimingFunctionSystem)
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

		let messageClasses: String = {
			let base = "message-view message-\(type.value)"
			let inlinePart = inline ? " message-inline" : ""
			let fadePart = fadeIn ? " message-fade-in" : ""
			let classPart = `class`.isEmpty ? "" : " \(`class`)"
			return "\(base)\(inlinePart)\(fadePart)\(classPart)"
		}()

		var message = div {
			if shouldShowIcon {
				span {
					displayIcon
				}
				.class("message-icon")
				.ariaHidden(true)
				.style {
					messageIconCSS(type)
				}
			}

			div {
				content
			}
			.class("message-content")
			.style {
				messageContentCSS()
			}

			if allowUserDismiss {
				button {
					CloseIconView(width: sizeIconMedium, height: sizeIconMedium)
				}
				.type(.button)
				.class("message-dismiss")
				.ariaLabel(dismissButtonLabel)
				.style {
					messageDismissCSS()
				}
			}
		}
		.class(messageClasses)
		.ariaLive(ariaLive)

		if let role = role {
			message = message.role(role)
		}

		if let autoDismissValue = autoDismissValue {
			message = message.data("auto-dismiss", "\(autoDismissValue)")
		}

		return message
			.style {
				messageViewCSS(type, inline)
				if fadeIn {
					messageFadeInCSS()
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

/// Dynamic message creation functions
public enum MessageAPI {
	/// Message type for dynamic messages
	public enum MessageType: Sendable {
		case notice
		case warning
		case error
		case success
	}

	/// Show a dynamic message without page reload
	public static func show(
		_ text: String,
		type: MessageType = .notice,
		inline: Bool = false,
		customIcon: String? = nil,
		allowUserDismiss: Bool = true,
		autoDismiss: Bool = false,
		autoDismissTime: Int = 4000,
		container: Element? = nil,
		onDismiss: (@Sendable () -> Void)? = nil
	) {

		let messageContainer: Element

		if let providedContainer = container {
			messageContainer = providedContainer
		} else if let pageMessages = document.querySelector(".page-messages") {
			messageContainer = pageMessages
		} else {
			var existingContainer = document.querySelector(".message-container")
			if existingContainer == nil {
				let newContainer = document.createElement(.div)
				newContainer.className = "message-container"
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
			messageContainer = c
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

		// Create message element
		let messageEl = document.createElement(.div)
		let messageClass: String
		switch type {
			case .notice:
				messageClass = "message-view message-notice message-fade-in"
			case .warning:
				messageClass = "message-view message-warning message-fade-in"
			case .error:
				messageClass = "message-view message-error message-fade-in"
			case .success:
				messageClass = "message-view message-success message-fade-in"
		}
		messageEl.className = messageClass
		messageEl.setAttribute(.ariaLive, ariaLive)
		if type == .error {
			messageEl.setAttribute(.role, .alert)
		}
		
		messageEl.style.display(.flex)
		messageEl.style.boxSizing(.borderBox)
		messageEl.style.pointerEvents(.auto)
		messageEl.style.animation(("message-fade-in", s(0.3), .easeOut))

		if !inline {
			messageEl.style.minHeight(px(64))
			messageEl.style.padding(spacing12, spacing16)
			messageEl.style.borderWidth(borderWidthBase)
			messageEl.style.borderStyle(.solid)
			messageEl.style.borderRadius(borderRadiusBase)
			messageEl.style.backgroundColor(bgColor)
			messageEl.style.borderColor(borderColor)
			messageEl.style.boxShadow((0, px(2), px(8), rgba(0, 0, 0, 0.1)))
		} else {
			messageEl.style.padding(px(0))
		}

		// Icon
		if shouldShowIcon {
			let icon = document.createElement(.span)
			icon.className = "message-icon"
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
			messageEl.appendChild(icon)
		}

		// Content
		let content = document.createElement(.div)
		content.className = "message-content"
		content.innerHTML = text
		content.style.display(.flex)
		content.style.flexDirection(.column)
		content.style.flexGrow(1)
		content.style.fontFamily(typographyFontSans)
		content.style.fontSize(fontSizeMedium16)
		content.style.fontWeight(fontWeightNormal)
		content.style.lineHeight(lineHeightSmall22)
		content.style.color(colorBase)
		messageEl.appendChild(content)

		// Dismiss button
		if allowUserDismiss {
            
			let dismissBtn = document.createElement(.button)
			dismissBtn.className = "message-dismiss"
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
				dismissMessage(messageEl, onDismiss: onDismiss, userInitiated: true)
			}

			messageEl.appendChild(dismissBtn)
            
		}
		// Add to container
		messageContainer.appendChild(messageEl)

		// Auto-dismiss
		if autoDismiss && type != .error {
			_ = setTimeout(autoDismissTime) {
				dismissMessage(messageEl, onDismiss: onDismiss, userInitiated: false)
			}
		}
	}

	private static func dismissMessage(_ element: Element, onDismiss: (@Sendable () -> Void)?, userInitiated: Bool) {
		element.style.animation(("message-fade-out", s(0.3), .easeOut))

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

private class MessageInstance: @unchecked Sendable {
	private var messageElement: Element
	private var dismissButton: Element?
	private var autoDismissTimer: Int32?

	init(message: Element) {
		self.messageElement = message
		self.dismissButton = message.querySelector(".message-dismiss")

		bindEvents()
		setupAutoDismiss()
	}

	private func bindEvents() {
		guard let button = dismissButton else { return }

		_ = button.on(.click) { [self] _ in
			self.dismissMessage(userInitiated: true)
		}
	}

	private func setupAutoDismiss() {
		guard let autoDismissAttr = messageElement.getAttribute(data("auto-dismiss")),
			let ms = localParseInt(autoDismissAttr) else {
			return
		}

		autoDismissTimer = setTimeout(ms) { [self] in
		self.dismissMessage(userInitiated: false)
		}
	}

	private func dismissMessage(userInitiated: Bool) {
		if let timer = autoDismissTimer {
			clearTimeout(timer)
			autoDismissTimer = nil
		}

		messageElement.style.animation(("message-fade-out", s(0.3), .easeOut))

		_ = setTimeout(300) { [self] in
			self.messageElement.remove()

			let eventType: String
			if userInitiated {
				eventType = "user_dismissed"
			} else {
				eventType = "auto_dismissed"
			}
			let event = CustomEvent(type: eventType, detail: "")
			self.messageElement.dispatchEvent(event)
		}
	}
}

/// Hydration for server-rendered messages
public class MessageHydration: @unchecked Sendable {
	private var instances: [MessageInstance] = []

	public init() {
		hydrateAllMessages()
	}

	private func hydrateAllMessages() {
		let allMessages = document.querySelectorAll(".message-view")

		for msg in allMessages {
			let instance = MessageInstance(message: msg)
			instances.append(instance)
		}
	}
}

#endif
