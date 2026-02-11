#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Banner component to remind users to verify their email
public struct EmailVerificationBannerView: HTMLProtocol {
	let email: String
	let `class`: String

	public init(email: String, class: String = "") {
		self.email = email
		self.`class` = `class`
	}

	public func render(indent: Int = 0) -> String {
		div {
			div {
				// Icon
				span { "⚠️" }
				.style {
					fontSize(fontSizeMedium16)
				}

				// Alert
				span {
					"Please verify your email address. We sent a verification email to "
					strong { email }
					"."
				}
				.style {
					fontSize(fontSizeSmall14)
					color(colorBase)
					flex(1)
				}

				// Resend button
				button { "Resend Email" }
				.type(.button)
				.class("resend-verification-email")
				.data("email", email)
				.style {
					padding(spacing8, spacing12)
					backgroundColor(backgroundColorBase)
					color(colorBlue)
					border(borderWidthBase, .solid, borderColorBlue)
					borderRadius(borderRadiusBase)
					fontSize(fontSizeSmall14)
					fontWeight(fontWeightBold)
					fontFamily(fontFamilyBase)
					cursor(cursorBaseHover)
					transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
					pseudoClass(.hover) {
						backgroundColor(backgroundColorBlueSubtle)
					}
					pseudoClass(.active) {
						backgroundColor(backgroundColorBlueSubtleActive)
					}
				}

				// Dismiss button
				button { "✕" }
				.type(.button)
				.class("dismiss-verification-banner")
				.ariaLabel("Dismiss")
				.style {
					padding(spacing8, spacing12)
					backgroundColor(.transparent)
					color(colorSubtle)
					border(.none)
					fontSize(fontSizeMedium16)
					cursor(cursorBaseHover)
					transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
					pseudoClass(.hover) {
						color(colorBase)
					}
				}
			}
			.style {
				display(.flex)
				alignItems(.center)
				gap(spacing12)
				maxWidth(px(1200))
				margin(0, .auto)
			}
		}
		.class(`class`.isEmpty ? "email-verification-banner" : "email-verification-banner \(`class`)")
		.data("hydrate", "email-verification-banner")
		.style {
			backgroundColor(backgroundColorOrangeSubtle)
			borderBlockEnd(borderWidthBase, .solid, borderColorOrange)
			padding(spacing12, spacing16)
		}
		.render(indent: indent)
	}
}

#endif

#if os(WASI)

import WebAPIs
import EmbeddedSwiftUtilities

public class EmailVerificationBannerHydration: @unchecked Sendable {
	nonisolated(unsafe) private var banner: Element?
	nonisolated(unsafe) private var resendButton: Element?
	nonisolated(unsafe) private var dismissButton: Element?

	public init?() {
		banner = document.querySelector(".email-verification-banner")
		guard let _ = banner else {
			return nil
		}

		resendButton = document.querySelector(".resend-verification-email")
		dismissButton = document.querySelector(".dismiss-verification-banner")

		bindEvents()
	}

	nonisolated private func bindEvents() {
		// Handle resend button
		if let resend = resendButton {
			_ = resend.addEventListener(.click) { [self] _ in
				self.handleResendEmail()
			}
		}

		// Handle dismiss button
		if let dismiss = dismissButton {
			_ = dismiss.addEventListener(.click) { [self] _ in
				self.handleDismiss()
			}
		}
	}

	nonisolated private func handleResendEmail() {
		guard let button = resendButton else { return }
		guard let email = button.getAttribute("data-email") else { return }

		// Disable button
		button.disabled = true
		button.textContent = "Sending..."

		// Send request to resend verification email
		window.fetch("/auth/resend-verification", method: "POST", body: "email=\(email)") { [self] response in
			let jsonString = response.text()

			let isSuccess = jsonString.utf8.withContiguousStorageIfAvailable { jsonBytes -> Bool in
				let successPattern = "\"success\":true".utf8
				let patternArray = Array(successPattern)
				let patternCount = patternArray.count

				guard jsonBytes.count >= patternCount else { return false }

				for startIndex in 0...(jsonBytes.count - patternCount) {
					var match = true
					for offset in 0..<patternCount {
						if jsonBytes[startIndex + offset] != patternArray[offset] {
							match = false
							break
						}
					}
					if match {
						return true
					}
				}
				return false
			} ?? false

			if isSuccess {
				AlertAPI.showSuccess("Verification email sent! Please check your inbox.")
				if let btn = self.resendButton {
					btn.textContent = "Email Sent"
				}
			} else {
				AlertAPI.showError("Failed to send verification email. Please try again.")
				if let btn = self.resendButton {
					btn.disabled = false
					btn.textContent = "Resend Email"
				}
			}
		}
	}

	nonisolated private func handleDismiss() {
		if let banner = banner {
			banner.style.display(.none)
		}
	}
}

#endif
