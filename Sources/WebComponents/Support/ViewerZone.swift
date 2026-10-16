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
/// client; on the server, the zone the request named (its `tz` query
/// parameter, which the client adds to the requests that count the reader's
/// days—nothing is stored on the reader's device), bound for the render by
/// the server (`ViewerZone.$named`), UTC where none is named. Moments travel
/// as UTC—minutes since the epoch—and become local days and times only here.
public enum ViewerZone {
  #if SERVER
    /// The IANA zone the request named ("Asia/Kolkata"); nil where it named
    /// none, and a figure summed by the reader's days is not yet known.
    @TaskLocal public static var named: String?

    /// The request's IANA zone, UTC where it named none.
    public static var identifier: String { named ?? "UTC" }

    /// Whether the request named the reader's zone: a figure summed by the
    /// reader's days ("today", "this month") is known only then; otherwise
    /// it reads "—" until the client asks again with the zone.
    public static var isNamed: Bool { named != nil }
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
  extension ViewerZone {
    /// `url` with the reader's zone as its `tz` query parameter, in place of
    /// any it held: for a request whose answer counts the reader's days (a
    /// live region summed by day, a relative range of days). The zone's `/`
    /// stays as it is, as a query may hold it; a `+` (`Etc/GMT+5`) is
    /// escaped, or it would read as a space.
    public static func zoned(_ url: String) -> String {
      let bytes = Array(url.utf8)
      let end = bytes.firstIndex(of: 35) ?? bytes.count  // "#"
      let question = bytes[..<end].firstIndex(of: 63)  // "?"
      var out = Array(bytes[..<(question ?? end)])
      out.append(63)
      if let question {
        for pair in bytes[(question + 1)..<end].split(separator: 38) {  // "&"
          if pair.starts(with: [116, 122, 61]) { continue }  // "tz="
          out.append(contentsOf: pair)
          out.append(38)
        }
      }
      out.append(contentsOf: [116, 122, 61])
      for byte in Array(name().utf8) {
        if byte == 43 { out.append(contentsOf: [37, 50, 66]) } else { out.append(byte) }  // "+" as "%2B"
      }
      out.append(contentsOf: bytes[end...])
      return String(decoding: out, as: UTF8.self)
    }

    /// `url` zoned when its query counts the reader's days, as it is
    /// otherwise: a sort header's or a pager's address.
    public static func zonedIfCounting(_ url: String) -> String {
      countsReaderDays(url) ? zoned(url) : url
    }

    /// Whether a URL's query (or a form's, `a=b&c=d`) counts the reader's
    /// days: a range counting back from now, or a span of the day.
    public static func countsReaderDays(_ url: String) -> Bool {
      let bytes = Array(url.utf8)
      let end = bytes.firstIndex(of: 35) ?? bytes.count
      let start = bytes[..<end].firstIndex(of: 63).map { $0 + 1 } ?? 0
      let query = String(decoding: bytes[start..<end], as: UTF8.self)
      return ViewerZoneHydration.countsRelativeRange(query) || ViewerZoneHydration.carriesTimeSpan(query)
    }
  }

  /// Sends the reader's zone—the browser's IANA zone—with the requests that
  /// count the reader's days, and with no other; nothing is stored on the
  /// reader's device (no cookie, no storage), so nothing needs consent:
  ///
  /// - a link or a GET form whose query counts the reader's days (a range
  ///   counting back from now, `-7d..`, or a span of the day), followed or
  ///   submitted, carries `tz` in its URL;
  /// - a live region summed by the reader's days (`data-reader-days`)
  ///   opens its stream with `tz` (`LiveRegionHydration`);
  /// - an element the server drew without the zone, its figures summed by
  ///   the reader's days not yet known (`data-reader-days` naming where they
  ///   are read), loads them at once with `tz`.
  ///
  /// The page is never read again: what was drawn without the zone shows
  /// "—", never another zone's days.
  public enum ViewerZoneHydration {
    public static func hydrateIfPresent() {
      _ = document.addEventListener(.click, { (event: Event) in zoneLink(event) }, capture: true)
      _ = document.addEventListener("auxclick", { (event: Event) in zoneLink(event) }, capture: true)
      _ = document.addEventListener(.submit, { (event: Event) in zoneForm(event) }, capture: true)
      for element in document.querySelectorAll("[data-reader-days]") {
        let source = element.getAttribute(data("reader-days")) ?? ""
        guard !stringIsEmpty(source), element.closest(".live-region-view") == nil else { continue }
        FragmentHostView.load(element, url: ViewerZone.zoned(source))
      }
    }

    /// A link of the site's own, as it is followed (clicked, middle-clicked
    /// or entered), carries the zone when its query counts the reader's days.
    static func zoneLink(_ event: Event) {
      guard let link = event.target?.closest("a[href]"), let href = link.getAttribute("href"),
        !stringContains(href, "//"), ViewerZone.countsReaderDays(href)
      else { return }
      link.setAttribute("href", ViewerZone.zoned(href))
    }

    /// A GET form, as it is submitted (before its entries are read),
    /// carries the zone as a hidden `tz` while what it asks counts the
    /// reader's days; one asked again without them drops it.
    static func zoneForm(_ event: Event) {
      guard let form = event.target?.closest("form") else { return }
      let method = form.getAttribute("method") ?? "get"
      if stringEquals(method, "post") || stringEquals(method, "POST") { return }
      form.querySelector("input.viewer-zone-input")?.remove()
      guard ViewerZone.countsReaderDays(FormData(form).toString()) else { return }
      let input = document.createElement("input")
      input.setAttribute("type", "hidden")
      input.setAttribute("name", "tz")
      input.setAttribute("value", ViewerZone.name())
      input.setAttribute("class", "viewer-zone-input")
      form.appendChild(input)
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
