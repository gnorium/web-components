#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// The reminder, at the top of a page's content, that the signed-in
  /// account's email address is unverified: the design system's warning
  /// alert (its icon, colors and close control; dismissing it is
  /// `AlertHydration`'s), with Resend email as the alert's own action: a button (it posts), drawn
  /// as a link — blue text, no fill — so it doesn't sit on the alert as a pill.
  /// `EmailVerificationBannerHydration` sends the link again.
  public struct EmailVerificationBannerView: HTMLContent {
    let email: String
    let `class`: String

    public init(email: String, class: String = "") {
      self.email = email
      self.`class` = `class`
    }

    public func build() -> DOM.Node {
      AlertView(
        color: .orange, allowUserDismiss: true, dismissButtonLabel: "Dismiss",
        class: `class`.isEmpty ? "email-verification-banner-view" : "email-verification-banner-view \(`class`)"
      ) {
        div {
          span {
            "Verify your email address: we sent a link to "
            strong { email }
            "."
          }
          .class("email-verification-banner-message")

          ButtonView(
            label: "Resend email", buttonColor: .blue, weight: .plain, size: .medium,
            class: "email-verification-banner-resend")
        }
        .class("email-verification-banner-content")
        .style {
          // The message and its action on one line where they fit; on a
          // phone the action wraps under the message.
          selector("&") {
            display(.flex)
            flexWrap(.wrap)
            alignItems(.center)
            columnGap(spacing12)
            rowGap(spacing4)
          }
          descendant(".email-verification-banner-message") {
            flex(1, 1, px(240))
            minWidth(0)
            overflowWrap(.anywhere)
          }
          // The address is emphasized as all emphasis is: semibold.
          descendant(".email-verification-banner-message strong") { fontWeight(fontWeightSemiBold) }
        }
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

  /// Resend email on ``EmailVerificationBannerView``: the server sends a new
  /// link to the signed-in account's own address (the request names none).
  /// The close control is the alert's own (`AlertHydration`).
  public class EmailVerificationBannerHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: EmailVerificationBannerHydration?

    public static func hydrateIfPresent() {
      guard let banner = document.querySelector(".email-verification-banner-view"),
        let resend = banner.querySelector(".email-verification-banner-resend")
      else { return }
      instance = EmailVerificationBannerHydration(resend: resend)
    }

    private let resend: DOM.Element

    private init(resend: DOM.Element) {
      self.resend = resend
      _ = resend.addEventListener(.click) { [self] _ in
        self.send()
      }
    }

    private func send() {
      setLabel("Sending…", disabled: true)
      window.fetch("/auth/resend-verification", method: "POST", body: "") { [self] response in
        if stringContains(response.text(), "\"success\":true") {
          AlertAPI.showSuccess("We sent a new link. Check your inbox.")
          self.setLabel("Email sent", disabled: true)
        } else {
          AlertAPI.showError("The email didn't send. Try again.")
          self.setLabel("Resend email", disabled: false)
        }
      }
    }

    private func setLabel(_ text: String, disabled: Bool) {
      // A disabled ButtonView's own marks: `disabled` and `aria-disabled`.
      if disabled {
        _ = resend.setAttribute("disabled", "disabled")
        _ = resend.setAttribute("aria-disabled", "true")
      } else {
        resend.removeAttribute("disabled")
        resend.removeAttribute("aria-disabled")
      }
      resend.querySelector(".button-label")?.textContent = text
    }
  }
#endif
