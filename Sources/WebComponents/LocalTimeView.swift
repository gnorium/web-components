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
    /// The sizes a stamp comes in.
    ///
    /// A closed set, deliberately. The size used to be any `CSS.Length` the
    /// caller liked, and the rule was written with that value inside its own
    /// selector—so each distinct value needed a rule of its own, and only the
    /// ones the stylesheet catalog happened to build ever got one. Every
    /// other stamp rendered with no size rule at all.
    ///
    /// Variants can be cataloged because there are finitely many of them.
    /// Arbitrary values cannot. That is the whole difference, and it is why a
    /// component's styling varies over named variants and never over values.
    public enum Size: String, Sendable, CaseIterable {
      case xSmall12 = "x-small-12"
      case small14 = "small-14"
      case medium16 = "medium-16"

      var length: CSS.Length {
        switch self {
        case .xSmall12: return fontSizeXSmall12
        case .small14: return fontSizeSmall14
        case .medium16: return fontSizeMedium16
        }
      }
    }

    /// The colors a stamp comes in, for the same reason.
    public enum Tone: String, Sendable, CaseIterable {
      case base
      case subtle

      var color: CSS.Color {
        switch self {
        case .base: return colorBase
        case .subtle: return colorSubtle
        }
      }
    }

    /// What of the moment a stamp shows: the day and time ("Jun 15, 2026
    /// at 9:10 AM"), the day alone ("Jun 15, 2026"), as a table's "on"
    /// column, or the time alone ("9:10 AM"), as its "at" column.
    public enum Format: String, Sendable {
      case dateTime = "date-time"
      case date
      case time
    }

    let date: Date
    let size: Size
    let tone: Tone
    let format: Format
    let fallbackSuffix: String

    public init(
      date: Date,
      size: Size = .xSmall12,
      tone: Tone = .base,
      format: Format = .dateTime,
      fallbackSuffix: String = "UTC"
    ) {
      self.date = date
      self.size = size
      self.tone = tone
      self.format = format
      self.fallbackSuffix = fallbackSuffix
    }

    public func build() -> DOM.Node {
      let isoFormatter = ISO8601DateFormatter()
      // Match client `formatLocalDate`: "Jun 15, 2026 at 9:10 AM" (+ UTC before hydrate)
      let displayFormatter = DateFormatter()
      displayFormatter.locale = Locale(identifier: "en_US_POSIX")
      displayFormatter.timeZone = TimeZone(identifier: "UTC")
      displayFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"

      // A day or a time alone is drawn in the zone the request named
      // (ViewerZone), which the client keeps or corrects; it names no zone.
      let partFormatter = DateFormatter()
      partFormatter.locale = Locale(identifier: "en_US_POSIX")
      partFormatter.timeZone = TimeZone(identifier: ViewerZone.identifier) ?? TimeZone(identifier: "UTC")
      partFormatter.dateFormat = format == .date ? "MMM d, yyyy" : "h:mm a"
      let text = format == .dateTime
        ? displayFormatter.string(from: date) + " " + fallbackSuffix : partFormatter.string(from: date)

      return time { text }
        .datetime(isoFormatter.string(from: date))
        .data("format", format.rawValue)
        .class("local-time-view local-time-\(size.rawValue) local-time-\(tone.rawValue)")
        .style {
          // Every variant, every time. The set is small and closed, so the
          // sheet holds all of it and one file serves every stamp on the site.
          for variant in Size.allCases {
            selector("&.local-time-\(variant.rawValue)") {
              fontSize(variant.length)
            }
          }
          for variant in Tone.allCases {
            selector("&.local-time-\(variant.rawValue)") {
              color(variant.color)
            }
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

  /// Hydrates all `<time class="local-time-view">` elements on the page,
  /// converting their UTC fallback text to the user's local timezone—and,
  /// the same way, any element carrying `data-local-time-iso`, whose stamp is
  /// one part of a sentence rather than the whole of it.
  public class LocalTimeHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: LocalTimeHydration?

    public init() {
      hydrate()
    }

    public static func hydrateIfPresent() {
      guard
        document.querySelector(".local-time-view") != nil
          || document.querySelector("[data-local-time-iso]") != nil
      else { return }
      instance = LocalTimeHydration()
    }

    public func hydrate() {
      let elements = document.querySelectorAll("time.local-time-view")
      for element in elements {
        guard let iso = element.getAttribute("datetime") else { continue }
        // A table's "on" or "at" cell: the day or the time alone, in the
        // reader's clock.
        if let format = element.getAttribute(data("format")), !stringEquals(format, "date-time") {
          guard let minutes = DateRangeValue.parseInstant(stringSubstring(iso, from: 0, to: 16) + "Z") else { continue }
          let moment = JSDate(time: Double(minutes) * 60_000)
          let text = stringEquals(format, "date")
            ? CalendarDate(year: moment.fullYear, month: moment.month + 1, day: moment.date).display
            : TimeOfDay(hour: moment.hours, minute: moment.minutes).text12
          element.textContent = text
          element.closest("td")?.setAttribute("title", text)
          continue
        }
        guard let localString = formatLocalDate(iso) else { continue }
        element.textContent = localString
        element.setAttribute("title", localString)
        element.closest("td")?.setAttribute("title", localString)
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
