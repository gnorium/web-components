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
  ///
  /// The same alert, blue, tells someone registering that the link which
  /// opens registration's second step is on its way (`Purpose.registration`).
  public struct EmailVerificationBannerView: HTMLContent {
    /// What the link it sends is for.
    public enum Purpose: Sendable {
      /// The signed-in account's own address, unverified: a warning.
      case unverified
      /// Registration's first step done: the address's link, which opens
      /// the second.
      case registration
    }

    let email: String
    let purpose: Purpose
    /// The seconds before another link may be sent: the button counts them
    /// down from the start (`EmailVerification.resendCooldown`).
    let cooldown: Int
    let `class`: String

    public init(email: String, purpose: Purpose = .unverified, cooldown: Int = 0, class: String = "") {
      self.email = email
      self.purpose = purpose
      self.cooldown = cooldown
      self.`class` = `class`
    }

    public func build() -> DOM.Node {
      AlertView(
        color: purpose == .registration ? .blue : .orange, allowUserDismiss: purpose == .unverified,
        dismissButtonLabel: "Dismiss",
        class: `class`.isEmpty ? "email-verification-banner-view" : "email-verification-banner-view \(`class`)"
      ) {
        div {
          span {
            switch purpose {
            case .unverified:
              "Verify your email address: we sent a link to "
              strong { email }
              "."
            case .registration:
              "Check your email: we sent a link to "
              strong { email }
              ". Open it to choose your username and password."
            }
          }
          .class("email-verification-banner-message")

          ButtonView(
            label: "Resend Email", buttonColor: .blue, weight: .plain, size: .medium,
            class: "email-verification-banner-resend")
        }
        .class("email-verification-banner-content")
        .data("resend-url", purpose == .registration ? "/auth/register/resend" : "/auth/resend-verification")
        .data("cooldown", "\(cooldown)")
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
  /// The button is disabled while it sends, then for a minute after a link
  /// goes, counting down ("Resend in 59s"), as the server refuses a new link
  /// sooner (429); the outcome is an alert of its own just above the banner—green
  /// when the link went, red when it didn't—replacing the last one. The close
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
      // A link sent moments ago (registration's first step): the wait the
      // server named, counted down from the start.
      let waiting = banner.querySelector(".email-verification-banner-content")?.getAttribute("data-cooldown") ?? "0"
      if let seconds = Self.retryAfter(in: stringJoin(["\"retryAfter\":", waiting], separator: "")), seconds > 0 {
        setDisabled(true)
        coolDown(seconds)
      }
    }

    private func send() {
      setDisabled(true)
      let url = banner.querySelector(".email-verification-banner-content")?.getAttribute("data-resend-url")
        ?? "/auth/resend-verification"
      window.fetch(url, method: "POST", body: "") { [self] response in
        let slot = self.notices()
        if stringContains(response.text(), "\"success\":true") {
          // The address the banner names, as the server sent to it.
          // Read with no `??`: that selects HTMLContent's nil default
          // instead of the DOM's text (gnorium-textcontent-optional-trap).
          let content = document.createElement(.span)
          content.textContent = "We sent a new verification link."
          if let address = self.banner.querySelector(".email-verification-banner-message strong") {
            let email = address.textContent
            if !stringIsEmpty(email) {
              content.textContent = "We sent a new verification link to "
              let emphasis = document.createElement(.strong)
              emphasis.textContent = email
              emphasis.style.setProperty("font-weight", "var(--font-weight-semi-bold)")
              content.appendChild(emphasis)
              let period = document.createElement(.span)
              period.textContent = "."
              content.appendChild(period)
            }
          }
          // Build the complete message before the alert measures its opening height.
          AlertAPI.showSuccess(content.innerHTML, container: slot)
          self.coolDown(Self.cooldownSeconds)
        } else if let seconds = Self.retryAfter(in: response.text()) {
          // Too soon since the last link: the server's 429 says how long.
          self.coolDown(seconds)
        } else {
          AlertAPI.showError("The email wasn't able to be sent.", container: slot)
          self.setDisabled(false)
        }
      }
    }

    /// The wait between links, as the server enforces it
    /// (`EmailVerification.resendCooldown`).
    static let cooldownSeconds = 60

    /// The button waits, counting down—"Resend in 59s"—then offers
    /// Resend Email again.
    private func coolDown(_ seconds: Int) {
      guard seconds > 0 else {
        setLabel("Resend Email")
        setDisabled(false)
        return
      }
      setDisabled(true)
      setLabel("Resend in \(seconds)s")
      _ = window.setTimeout(1000) { [self] in
        self.coolDown(seconds - 1)
      }
    }

    /// The seconds a 429 answer's `"retryAfter":` names; nil for any other
    /// answer.
    static func retryAfter(in body: String) -> Int? {
      let key = "\"retryAfter\":"
      guard let start = stringIndexOf(body, key) else { return nil }
      var value = 0
      var digits = 0
      var index = 0
      for byte in body.utf8 {
        if index >= start + key.utf8.count {
          if byte >= 48 && byte <= 57 {
            value = value * 10 + Int(byte - 48)
            digits += 1
          } else if digits > 0 || byte != 32 {
            break
          }
        }
        index += 1
      }
      return digits > 0 ? value : nil
    }

    private func setLabel(_ text: String) {
      resend.querySelector(".button-label")?.textContent = text
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
