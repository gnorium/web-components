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
      let displayFormatter = DateFormatter()
      displayFormatter.dateStyle = .medium
      displayFormatter.timeStyle = .short
      displayFormatter.timeZone = TimeZone(identifier: "UTC")

      return time { displayFormatter.string(from: date) + " " + fallbackSuffix }
        .datetime(isoFormatter.string(from: date))
        .class("local-time")
        .style {
          fontSize(size)
          color(textColor)
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
  /// converting their UTC fallback text to the user's local timezone.
  public class LocalTimeHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: LocalTimeHydration?

    public init() {
      hydrate()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".local-time") != nil else { return }
      instance = LocalTimeHydration()
    }

    public func hydrate() {
      let elements = document.querySelectorAll("time.local-time")
      for element in elements {
        guard let iso = element.getAttribute("datetime") else { continue }
        guard let localString = formatLocalDate(iso) else { continue }
        element.textContent = localString
      }
    }
  }
#endif
