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
      case medium16 = "medium-16"

      var length: CSS.Length {
        switch self {
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
    /// column, the time alone ("9:10 AM"), as its "at" column, or the exact
    /// instant—to the second ("Oct 16, 2026 at 12:52:22 PM"), where the
    /// second matters (a payment's time). Once hydrated, no stamp names a
    /// zone: it is the reader's own local time. Only the server's text,
    /// before hydration, carries the "UTC" suffix, because it is not local.
    public enum Format: String, Sendable {
      case dateTime = "date-time"
      case instant
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
      size: Size = .medium16,
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
      return time { Self.text(date, format: format, fallbackSuffix: fallbackSuffix) }
        .datetime(Self.iso(date))
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

    /// The stamp's words, drawn by integer arithmetic on the calendar—never
    /// a `DateFormatter`. On Linux a formatter given the reader's zone hands
    /// it to CoreFoundation, which loads the zone's file from the image's
    /// tzdata and traps when that file is missing: a browser's
    /// "Asia/Calcutta" is a zone ICU knows (so the request binds it) but one
    /// Ubuntu's tzdata no longer ships (it moved to tzdata-legacy), and the
    /// first table to draw a day or a time crashed the server (2026-10-16).
    /// The offset comes from `ViewerZone`, the same as every other local day.
    ///
    /// "Jun 15, 2026 at 9:10 AM UTC" (the day and time, UTC until the client
    /// hydrates), "Jun 15, 2026 at 9:10:05 AM UTC" (the instant), "Jun 15,
    /// 2026" (the day) or "9:10 AM" (the time), the last two in the reader's
    /// zone.
    static func text(_ date: Date, format: Format, fallbackSuffix: String) -> String {
      let seconds = Int64(date.timeIntervalSince1970.rounded(.down))
      let utcMinutes = seconds / 60 - (seconds % 60 < 0 ? 1 : 0)
      switch format {
      case .date:
        return ViewerZone.localDay(epochMinutes: utcMinutes).display
      case .time:
        return TimeOfDay(minutes: ViewerZone.wallMinutes(epochMinutes: utcMinutes, zone: ViewerZone.identifier)).text12
      case .dateTime, .instant:
        let day = CalendarDate(dayNumber: Int(utcMinutes / 1_440 - (utcMinutes % 1_440 < 0 ? 1 : 0)))
        let clock = TimeOfDay(minutes: Int(utcMinutes % 1_440))
        let second = Int(((seconds % 60) + 60) % 60)
        let time = format == .instant
          ? "\(clock.hour12):\(TimeOfDay.twoDigits(clock.minute)):\(TimeOfDay.twoDigits(second)) \(clock.isPM ? "PM" : "AM")"
          : clock.text12
        return "\(day.display) at \(time) \(fallbackSuffix)"
      }
    }

    /// The `datetime` attribute: ISO 8601 in UTC to the second
    /// ("2026-06-15T09:10:05Z"), as `ISO8601DateFormatter` wrote it.
    static func iso(_ date: Date) -> String {
      let seconds = Int64(date.timeIntervalSince1970.rounded(.down))
      let days = seconds / 86_400 - (seconds % 86_400 < 0 ? 1 : 0)
      let ofDay = Int(seconds - days * 86_400)
      let day = CalendarDate(dayNumber: Int(days))
      return "\(day.iso)T\(TimeOfDay.twoDigits(ofDay / 3_600)):\(TimeOfDay.twoDigits(ofDay / 60 % 60)):\(TimeOfDay.twoDigits(ofDay % 60))Z"
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
        let format = element.getAttribute(data("format")) ?? ""
        // The exact instant: to the second, with the reader's zone.
        if stringEquals(format, "instant") {
          guard let text = formatLocalInstant(iso) else { continue }
          element.textContent = text
          element.setAttribute("title", text)
          element.closest("td")?.setAttribute("title", text)
          continue
        }
        // A table's "on" or "at" cell: the day or the time alone, in the
        // reader's clock.
        if !stringIsEmpty(format), !stringEquals(format, "date-time") {
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
      //
      // Idempotent (user, 2026-10-12): a later pass (a live region, a
      // fragment) leaves a carrier it already wrote—marked with the moment it
      // wrote—and never writes into a tooltip's trigger, whose bubble has by
      // then moved to the page's portal: the trigger's own content (its ⓘ)
      // stays.
      for element in document.querySelectorAll("[data-local-time-iso]") {
        guard let iso = element.getAttribute("data-local-time-iso") else { continue }
        if stringEquals(element.dataset["localTimeWritten"] ?? "", iso) { continue }
        let bubble = element.querySelector(".tooltip-content")
        if stringContains(element.className, "tooltip-trigger"), bubble == nil { continue }
        guard let localString = formatLocalDate(iso) else { continue }
        let prefix = element.getAttribute("data-local-time-prefix") ?? ""
        let suffix = element.getAttribute("data-local-time-suffix") ?? ""
        let target = bubble ?? element
        target.textContent = stringJoin([prefix, localString, suffix], separator: "")
        element.dataset["localTimeWritten"] = iso
      }
    }
  }
#endif
