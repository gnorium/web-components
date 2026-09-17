#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// Renders a `<time>` element with an ISO 8601 `datetime` attribute and a UTC fallback display.
  /// WASM hydration converts the display to the user's local timezone.
  public struct LocalTimeView: HTMLContent {
    let date: Date
    let size: CSS.Length
    let textColor: CSS.Color
    let fallbackSuffix: String

    public init(
      date: Date,
      size: CSS.Length = fontSizeSmall14,
      textColor: CSS.Color = colorBase,
      fallbackSuffix: String = "UTC"
    ) {
      self.date = date
      self.size = size
      self.textColor = textColor
      self.fallbackSuffix = fallbackSuffix
    }

    public func build() -> DOM.Node {
      let isoFormatter = ISO8601DateFormatter()
      // Match client `formatLocalDate`: "Jun 15, 2026 at 9:10 AM" (+ UTC before hydrate)
      let displayFormatter = DateFormatter()
      displayFormatter.locale = Locale(identifier: "en_US_POSIX")
      displayFormatter.timeZone = TimeZone(identifier: "UTC")
      displayFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"

      return time { displayFormatter.string(from: date) + " " + fallbackSuffix }
        .datetime(isoFormatter.string(from: date))
        .class("local-time")
        .data("local-time-size", size.value)
        .data("local-time-color", textColor.value)
        .style {
          selector("&[data-local-time-size='\(size.value)'][data-local-time-color='\(textColor.value)']") {
            fontSize(size)
            color(textColor)
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

  /// Hydrates all `<time class="local-time">` elements on the page,
  /// converting their UTC fallback text to the user's local timezone — and,
  /// the same way, any element carrying `data-local-time-iso`, whose stamp is
  /// one part of a sentence rather than the whole of it.
  public class LocalTimeHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: LocalTimeHydration?

    public init() {
      hydrate()
    }

    public static func hydrateIfPresent() {
      guard
        document.querySelector(".local-time") != nil
          || document.querySelector("[data-local-time-iso]") != nil
      else { return }
      instance = LocalTimeHydration()
    }

    public func hydrate() {
      let elements = document.querySelectorAll("time.local-time")
      for element in elements {
        guard let iso = element.getAttribute("datetime") else { continue }
        guard let localString = formatLocalDate(iso) else { continue }
        element.textContent = localString
      }
      // A stamp inside a sentence: the two halves around it are given as
      // attributes, so the sentence is rebuilt rather than parsed. When the
      // carrier is a tooltip trigger the sentence lives in its bubble, which
      // is where the reader will see it.
      for element in document.querySelectorAll("[data-local-time-iso]") {
        guard let iso = element.getAttribute("data-local-time-iso") else { continue }
        guard let localString = formatLocalDate(iso) else { continue }
        let prefix = element.getAttribute("data-local-time-prefix") ?? ""
        let suffix = element.getAttribute("data-local-time-suffix") ?? ""
        let target = element.querySelector(".tooltip-content") ?? element
        target.textContent = stringJoin([prefix, localString, suffix], separator: "")
      }
    }
  }
#endif
