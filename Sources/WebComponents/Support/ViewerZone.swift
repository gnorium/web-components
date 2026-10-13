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

  #endif

  /// The reader's day a moment falls on.
  public static func localDay(epochMinutes: Int64) -> CalendarDate {
    #if CLIENT
      let date = JSDate(time: Double(epochMinutes) * 60_000)
      return CalendarDate(year: date.fullYear, month: date.month + 1, day: date.date)
    #else
      let local = epochMinutes + Int64(offsetMinutes(zone: identifier, epochMinutes: epochMinutes))
      let day = local / 1_440 - (local % 1_440 < 0 ? 1 : 0)
      return CalendarDate(dayNumber: Int(day))
    #endif
  }

  /// The moment the reader's day begins, as minutes since the epoch.
  public static func epochMinutes(startOf day: CalendarDate) -> Int64 {
    let wall = Int64(day.dayNumber) * 1_440
    #if CLIENT
      // Use literal Gregorian years. JavaScript's multi-argument Date
      // constructor silently maps years 0–99 to 1900–1999.
      return resolveWallMinutes(wall) { instant in
        let date = JSDate(time: Double(instant) * 60_000)
        let localDay = CalendarDate(year: date.fullYear, month: date.month + 1, day: date.date)
        return Int(Int64(localDay.dayNumber) * 1_440 + Int64(date.hours * 60 + date.minutes) - instant)
      }
    #else
      return resolveWallMinutes(wall) { offsetMinutes(zone: identifier, epochMinutes: $0) }
    #endif
  }

  /// Today where the reader is.
  public static func today() -> CalendarDate {
    localDay(epochMinutes: nowMinutes())
  }

  /// The current UTC minute, captured once when resolving a relative range.
  public static func nowMinutes() -> Int64 {
    #if CLIENT
      return Int64(JSDate.now() / 60_000)
    #else
      return Int64(Date().timeIntervalSince1970 / 60)
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
  public static func offsetMinutes(zone: String, epochMinutes: Int64) -> Int {
    #if CLIENT
      return JSDate.offsetMinutes(zone: zone, at: Double(epochMinutes) * 60_000)
    #else
      let timeZone = TimeZone(identifier: zone) ?? TimeZone(secondsFromGMT: 0)!
      let seconds = timeZone.secondsFromGMT(for: Date(timeIntervalSince1970: Double(epochMinutes) * 60))
      return seconds / 60 - (seconds % 60 < 0 ? 1 : 0)
    #endif
  }

  /// The moment `zone`'s clocks read `minutes` past midnight on `day`: the
  /// earlier occurrence is used for a repeated time. A skipped wall time
  /// moves forward by the transition's gap, including half-hour changes.
  public static func epochMinutes(day: CalendarDate, minutes: Int, zone: String) -> Int64 {
    resolveWallMinutes(Int64(day.dayNumber) * 1_440 + Int64(minutes)) {
      offsetMinutes(zone: zone, epochMinutes: $0)
    }
  }

  /// Probe both sides of a transition, then verify each possible instant
  /// against the offset in force there. Nearby offsets cover even a full
  /// skipped day. Exact matches win; a gap uses the nearest later wall time.
  static func resolveWallMinutes(_ wall: Int64, offset: (Int64) -> Int) -> Int64 {
    var exact: Int64?
    var forward: (instant: Int64, distance: Int64)?
    for probe in [wall - 2_880, wall, wall + 2_880] {
      let candidate = wall - Int64(offset(probe))
      let distance = candidate + Int64(offset(candidate)) - wall
      if distance == 0 {
        exact = exact.map { Swift.min($0, candidate) } ?? candidate
      } else if distance > 0 {
        if let previous = forward {
          if distance < previous.distance { forward = (candidate, distance) }
        } else {
          forward = (candidate, distance)
        }
      }
    }
    return exact ?? forward?.instant ?? (wall - Int64(offset(wall)))
  }

  /// What `zone`'s clocks read at a moment, as minutes past its midnight.
  public static func wallMinutes(epochMinutes: Int64, zone: String) -> Int {
    let local = epochMinutes + Int64(offsetMinutes(zone: zone, epochMinutes: epochMinutes))
    return Int(((local % 1_440) + 1_440) % 1_440)
  }
}

#if CLIENT
  /// Tells the server the reader's zone—the `tz` cookie, the browser's IANA
  /// zone—only when the reader filters by date or time: picks a preset, a
  /// range or a span (`remember`), or opens a link carrying a relative range
  /// or a span (`hydrateIfPresent`). A plain page view never sets it: the
  /// tables draw local times on the client (LocalTimeView); only counting a
  /// relative range's days needs the zone on the server.
  public enum ViewerZoneHydration {
    public static func hydrateIfPresent() {
      let query = window.location.search
      let relative = countsRelativeRange(query)
      guard relative || carriesTimeSpan(query) else { return }
      guard remember() else { return }
      // A relative range was counted on the server's clock: read once more,
      // on the reader's (once a tab, so a server that cannot read the zone
      // does not send the page back for ever).
      let zone = JSDate.resolvedTimeZone
      let reloaded = sessionStorage.getItem("gnorium:tz-reloaded") ?? ""
      if relative, !stringEquals(reloaded, zone) {
        sessionStorage.setItem("gnorium:tz-reloaded", zone)
        window.location.reload()
      }
    }

    /// Sets the cookie when the zone the page was drawn in
    /// (`<html data-time-zone>`) is not the browser's; whether it did.
    @discardableResult
    public static func remember() -> Bool {
      let zone = JSDate.resolvedTimeZone
      guard !stringIsEmpty(zone), let html = document.querySelector("html") else { return false }
      let drawn = html.getAttribute(data("time-zone")) ?? ""
      guard !stringEquals(zone, drawn) else { return false }
      document.setCookie(name: "tz", value: zone, maxAge: 31_536_000)
      html.setAttribute(data("time-zone"), zone)
      return true
    }

    /// Whether a query holds a range counting back from now: `=-7d..`,
    /// `=-1h..`.
    static func countsRelativeRange(_ query: String) -> Bool {
      let bytes = Array(query.utf8)
      var index = 0
      while index + 2 < bytes.count {
        if bytes[index] == 61, bytes[index + 1] == 45 {  // "=-"
          var cursor = index + 2
          while cursor < bytes.count, bytes[cursor] >= 48, bytes[cursor] <= 57 { cursor += 1 }
          if cursor > index + 2, cursor < bytes.count, bytes[cursor] == 100 || bytes[cursor] == 104 { return true }
        }
        index += 1
      }
      return false
    }

    /// Whether a query holds a span of the day, its zone in brackets.
    static func carriesTimeSpan(_ query: String) -> Bool {
      stringContains(query, "%5B") || stringContains(query, "[")
    }
  }
#endif
