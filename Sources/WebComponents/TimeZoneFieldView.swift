import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// The zone a form's local date and time is read in: the browser's own IANA
/// zone ("Asia/Kolkata"), submitted as a hidden field and shown read-only
/// beside the time it qualifies, so whoever enters the time sees which
/// zone it is taken in.
///
/// The server cannot know the zone, and never guesses one: before hydration
/// (or without scripts) the field is empty and the zone reads "—", and the
/// server refuses an empty zone (`TimeZoneFieldHydration`).
public struct TimeZoneFieldView: HTMLContent {
  let name: String
  let label: String

  public init(name: String, label: String = "Time zone") {
    self.name = name
    self.label = label
  }

  public func build() -> DOM.Node {
    div {
      input()
        .type(.hidden)
        .name(name)
        .value("")
        .class("time-zone-field-value")
      DatumView(label) {
        span { "—" }.class("time-zone-field-name")
      }
    }
    .class("time-zone-field-view")
    .build()
  }
}

#if CLIENT
  import WebAPIs

  /// Fills every `TimeZoneFieldView` with the browser's zone
  /// (`Intl.DateTimeFormat().resolvedOptions().timeZone`); one the browser
  /// does not name stays empty, and the server refuses it.
  public final class TimeZoneFieldHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: TimeZoneFieldHydration?

    public init() {
      let zone = JSDate.resolvedTimeZone
      guard !stringIsEmpty(zone) else { return }
      for root in document.querySelectorAll(".time-zone-field-view") {
        (root.querySelector(".time-zone-field-value") as? HTML.HTMLInputElement)?.value = zone
        root.querySelector(".time-zone-field-name")?.textContent = zone
      }
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".time-zone-field-view") != nil else { return }
      instance = TimeZoneFieldHydration()
    }
  }
#endif
