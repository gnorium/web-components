#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// The reminder, at the top of a page's content, that the signed-in
  /// account's email address is unverified: the design system's warning
  /// alert (its icon, colors and close control; dismissing it is
  /// `AlertHydration`'s), with Resend Email as the alert's own action: a plain blue button.
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
            label: "Resend Email", buttonColor: .blue, weight: .plain, size: .medium,
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

  /// Resend Email on ``EmailVerificationBannerView``: the server sends a new
  /// link to the signed-in account's own address (the request names none).
  /// The button keeps its label and is disabled only while it sends; the
  /// outcome is an alert of its own just above the banner — green when the
  /// link went, red when it didn't — replacing the last one. The close
  /// control is the alert's own (`AlertHydration`).
  public class EmailVerificationBannerHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: EmailVerificationBannerHydration?

    public static func hydrateIfPresent() {
      guard let banner = document.querySelector(".email-verification-banner-view"),
        let resend = banner.querySelector(".email-verification-banner-resend")
      else { return }
      instance = EmailVerificationBannerHydration(banner: banner, resend: resend)
    }

    private let banner: DOM.Element
    private let resend: DOM.Element

    private init(banner: DOM.Element, resend: DOM.Element) {
      self.banner = banner
      self.resend = resend
      _ = resend.addEventListener(.click) { [self] _ in
        self.send()
      }
    }

    private func send() {
      setDisabled(true)
      window.fetch("/auth/resend-verification", method: "POST", body: "") { [self] response in
        let slot = self.notices()
        if stringContains(response.text(), "\"success\":true") {
          // The address the banner names, as the server sent to it.
          // Read with no `??`: that selects HTMLContent's nil default
          // instead of the DOM's text (gnorium-textcontent-optional-trap).
          var to = ""
          if let address = self.banner.querySelector(".email-verification-banner-message strong") {
            let email = address.textContent
            if !stringIsEmpty(email) { to = " to \(email)" }
          }
          AlertAPI.showSuccess(
            "We sent a new verification link\(to).",
            container: slot)
        } else {
          AlertAPI.showError("The email didn't send. Try again.", container: slot)
        }
        self.setDisabled(false)
      }
    }

    /// The slot just above the banner that the outcome's alert stands in,
    /// emptied of the last outcome; made the first time.
    private func notices() -> DOM.Element {
      if let slot = document.querySelector(".email-verification-banner-notices") {
        slot.innerHTML = ""
        return slot
      }
      banner.insertAdjacentHTML(.beforebegin, "<div class=\"email-verification-banner-notices\"></div>")
      return document.querySelector(".email-verification-banner-notices") ?? banner
    }

    private func setDisabled(_ disabled: Bool) {
      // A disabled ButtonView's own marks: `disabled` and `aria-disabled`.
      if disabled {
        _ = resend.setAttribute("disabled", "disabled")
        _ = resend.setAttribute("aria-disabled", "true")
      } else {
        resend.removeAttribute("disabled")
        resend.removeAttribute("aria-disabled")
      }
    }
  }
#endif
