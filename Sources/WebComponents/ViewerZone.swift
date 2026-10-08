#if SERVER
  import Foundation
#endif
#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes
#endif

/// The reader's time zone, for what is shown in it: the browser's own on the
/// client; on the server, the zone the request named (`tz` cookie, set by the
/// client), bound for the render by the server (`ViewerZone.$identifier`),
/// UTC where none is named. Moments travel as UTC—minutes since the epoch—
/// and become local days and times only here.
public enum ViewerZone {
  #if SERVER
    /// The request's IANA zone ("Asia/Kolkata").
    @TaskLocal public static var identifier: String = "UTC"

    static var zone: TimeZone { TimeZone(identifier: identifier) ?? TimeZone(secondsFromGMT: 0)! }

    static var calendar: Calendar {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = zone
      return calendar
    }
  #endif

  /// The reader's day a moment falls on.
  public static func localDay(epochMinutes: Int) -> CalendarDate {
    #if CLIENT
      let date = JSDate(time: Double(epochMinutes) * 60_000)
      return CalendarDate(year: date.fullYear, month: date.month + 1, day: date.date)
    #else
      let parts = calendar.dateComponents(
        [.year, .month, .day], from: Date(timeIntervalSince1970: Double(epochMinutes) * 60))
      return CalendarDate(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    #endif
  }

  /// The moment the reader's day begins, as minutes since the epoch.
  public static func epochMinutes(startOf day: CalendarDate) -> Int {
    #if CLIENT
      let time = JSDate(localYear: day.year, month: day.month - 1, day: day.day).time
      let minutes = time / 60_000
      return Int(minutes)
    #else
      let date = calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day))
      return Int((date?.timeIntervalSince1970 ?? 0) / 60)
    #endif
  }

  /// Today where the reader is.
  public static func today() -> CalendarDate {
    #if CLIENT
      return localDay(epochMinutes: Int(JSDate.now() / 60_000))
    #else
      return localDay(epochMinutes: Int(Date().timeIntervalSince1970 / 60))
    #endif
  }

  /// The reader's zone by its IANA name ("America/New_York").
  public static func name() -> String {
    #if CLIENT
      let zone = JSDate.resolvedTimeZone
      return stringIsEmpty(zone) ? "UTC" : zone
    #else
      return identifier
    #endif
  }

  /// Minutes `zone` is ahead of UTC at a moment—its own offset that day,
  /// daylight saving included, from the IANA database (the browser's Intl
  /// on the client, Foundation's on the server).
  public static func offsetMinutes(zone: String, epochMinutes: Int) -> Int {
    #if CLIENT
      return JSDate.offsetMinutes(zone: zone, at: Double(epochMinutes) * 60_000)
    #else
      let timeZone = TimeZone(identifier: zone) ?? TimeZone(secondsFromGMT: 0)!
      return timeZone.secondsFromGMT(for: Date(timeIntervalSince1970: Double(epochMinutes) * 60)) / 60
    #endif
  }

  /// The moment `zone`'s clocks read `minutes` past midnight on `day`: the
  /// offset is the one in force then, found by asking twice (a guess, then
  /// the offset at the guess). A wall time a spring-forward skips lands an
  /// hour on, as the clocks do.
  public static func epochMinutes(day: CalendarDate, minutes: Int, zone: String) -> Int {
    let wall = day.dayNumber * 1_440 + minutes
    let first = wall - offsetMinutes(zone: zone, epochMinutes: wall)
    return wall - offsetMinutes(zone: zone, epochMinutes: first)
  }

  /// What `zone`'s clocks read at a moment, as minutes past its midnight.
  public static func wallMinutes(epochMinutes: Int, zone: String) -> Int {
    let local = epochMinutes + offsetMinutes(zone: zone, epochMinutes: epochMinutes)
    return ((local % 1_440) + 1_440) % 1_440
  }
}

#if CLIENT
  /// Tells the server the reader's zone: the `tz` cookie, the browser's IANA
  /// zone, which the server reads to count a relative range's days ("Last 7
  /// days") and to draw days and times in the reader's clock. Set when the
  /// zone the page was drawn in (`<html data-time-zone>`) is not the
  /// browser's; a page whose filters count relative days is then read
  /// again, so its rows are the reader's days the first time too.
  public enum ViewerZoneHydration {
    public static func hydrateIfPresent() {
      guard let html = document.querySelector("html"),
        let drawn = html.getAttribute(data("time-zone"))
      else { return }
      let zone = JSDate.resolvedTimeZone
      guard !stringIsEmpty(zone), !stringEquals(zone, drawn) else { return }
      document.setCookie(name: "tz", value: zone, maxAge: 31_536_000)
      // Read again once a tab: a server that cannot read the zone would
      // otherwise send the same page back for ever.
      let reloaded = sessionStorage.getItem("gnorium:tz-reloaded") ?? ""
      if countsRelativeDays(window.location.search), !stringEquals(reloaded, zone) {
        sessionStorage.setItem("gnorium:tz-reloaded", zone)
        window.location.reload()
      }
    }

    /// Whether a query holds a range counting back days: `=-7d..`.
    static func countsRelativeDays(_ query: String) -> Bool {
      let bytes = Array(query.utf8)
      var index = 0
      while index + 2 < bytes.count {
        if bytes[index] == 61, bytes[index + 1] == 45 {  // "=-"
          var cursor = index + 2
          while cursor < bytes.count, bytes[cursor] >= 48, bytes[cursor] <= 57 { cursor += 1 }
          if cursor > index + 2, cursor < bytes.count, bytes[cursor] == 100 { return true }  // "d"
        }
        index += 1
      }
      return false
    }
  }
#endif
