#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Banner component to remind users to verify their email
  public struct EmailVerificationBannerView: HTMLContent {
    let email: String
    let `class`: String

    public init(email: String, class: String = "") {
      self.email = email
      self.`class` = `class`
    }

    public func build() -> DOM.Node {
      div {
        div {
          // Icon
          span { StatusIconView(.warning) }
            .class("email-verification-banner-icon")
            .ariaHidden(true)

          // Alert
          span {
            "Please verify your email address. We sent a verification email to "
            strong { email }
            "."
          }
          .class("email-verification-banner-message")

          // Resend button
          button { "Resend Email" }
            .type(.button)
            .class("resend-verification-email")

          // Dismiss button
          button { "✕" }
            .type(.button)
            .class("dismiss-verification-banner")
            .ariaLabel("Dismiss")
        }
        .class("email-verification-banner-view")
      }
      .class(`class`.isEmpty ? "email-verification-banner" : "email-verification-banner \(`class`)")
      .data("hydrate", "email-verification-banner")
      .data("dismissed", false)
      .style {
        selector("&") {
          backgroundColor(backgroundColorOrangeSubtle)
          borderBlockEnd(borderWidthBase, .solid, borderColorOrange)
          padding(spacing12, spacing16)
        }
        selector("&[data-dismissed='true']") { display(.none) }
        descendant(".email-verification-banner-view") {
          display(.flex)
          alignItems(.center)
          gap(spacing12)
          maxWidth(px(1200))
          margin(0, .auto)
        }
        descendant(".email-verification-banner-icon") {
          display(.flex)
          flexShrink(0)
          color(colorOrange)
        }
        descendant(".email-verification-banner-message") {
          fontSize(fontSizeSmall14)
          color(colorBase)
          flex(1)
        }
        descendant(".resend-verification-email") {
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
        }
        descendant(".resend-verification-email:hover") { backgroundColor(backgroundColorBlueSubtle) }
        descendant(".resend-verification-email:active") { backgroundColor(backgroundColorBlueSubtleActive) }
        descendant(".dismiss-verification-banner") {
          padding(spacing8, spacing12)
          backgroundColor(.transparent)
          color(colorSubtle)
          border(.none)
          fontSize(fontSizeMedium16)
          cursor(cursorBaseHover)
          transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        }
        descendant(".dismiss-verification-banner:hover") { color(colorBase) }
      }
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  public class EmailVerificationBannerHydration: @unchecked Sendable {
    nonisolated(unsafe) private var banner: DOM.Element?
    nonisolated(unsafe) private var resendButton: DOM.Element?
    nonisolated(unsafe) private var dismissButton: DOM.Element?

    public init?() {
      banner = document.querySelector(".email-verification-banner")
      guard banner != nil else {
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

      // Disable button
      (button as? HTML.HTMLButtonElement)?.disabled = true
      button.textContent = "Sending..."

      // The server sends the link to the signed-in account's own address:
      // the request names no address.
      window.fetch("/auth/resend-verification", method: "POST", body: "") {
        [self] response in
        let jsonString = response.text()

        let isSuccess =
          jsonString.utf8.withContiguousStorageIfAvailable { jsonBytes -> Bool in
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
            (btn as? HTML.HTMLButtonElement)?.disabled = false
            btn.textContent = "Resend Email"
          }
        }
      }
    }

    nonisolated private func handleDismiss() {
      if let banner = banner {
        banner.setAttribute(data("dismissed"), "true")
      }
    }
  }
#endif
