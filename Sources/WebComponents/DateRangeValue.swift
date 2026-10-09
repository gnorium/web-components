import EmbeddedSwiftUtilities

/// A range of days as one URL value carries it, in one of two forms:
///
/// - fixed: two UTC instants, to the minute, that bound the reader's local
///   days—`2026-09-30T18:30Z..2026-10-08T18:30Z` is Oct 1–8 in India: the
///   start included, the end excluded (the next day's first moment). Either
///   end may be open (`2026-09-30T18:30Z..`, `..2026-10-08T18:30Z`). A link
///   so means the same moments wherever it is opened, and each reader sees
///   them as their own days.
/// - relative: `-7d..`, the seven days that end today, the reader's days;
///   `-1d..`, today; `-1h..`, the last hour. A relative range stays
///   relative: a bookmarked "Last 7 days" still means the last seven days
///   where and when it is opened (the server reads the reader's zone from
///   the `tz` cookie the client sets).
///
/// The picker turns local days into instants and back (`ViewerZone`); the
/// grammar itself is byte and integer work only, so the client reads one as
/// the server does.
public struct DateRangeValue: Sendable {
  public enum Bound: Sendable {
    /// A UTC moment, as minutes since the epoch.
    case instant(Int64)
    /// The N days that end today, the reader's: as a start, the first
    /// moment of the day N − 1 days back; as an end, the end of that day.
    case days(Int)
    /// N hours back from now.
    case hours(Int)
  }

  public let start: Bound?
  public let end: Bound?

  public init(start: Bound?, end: Bound?) {
    self.start = start
    self.end = end
  }

  /// The ranges a picker offers beside its calendar, as Google Analytics,
  /// Stripe and Grafana do: each relative, each ending today.
  public static let presets: [(value: String, label: String)] = [
    ("-1d..", "Today"), ("-7d..", "Last 7 days"), ("-30d..", "Last 30 days"), ("-90d..", "Last 90 days"),
  ]

  // MARK: - Reading and writing

  /// Reads `start..end`; nil for anything else, for an end not after its
  /// start, or for a range open at both ends.
  public static func parse(_ string: String) -> DateRangeValue? {
    let trimmed = stringTrim(string)
    guard let dots = stringIndexOf(trimmed, "..") else { return nil }
    let lower = stringSubstring(trimmed, from: 0, to: dots)
    let upper = stringSubstring(trimmed, from: dots + 2)
    var start: Bound?
    var end: Bound?
    if !stringIsEmpty(lower) {
      guard let bound = parseBound(lower) else { return nil }
      start = bound
    }
    if !stringIsEmpty(upper) {
      guard let bound = parseBound(upper) else { return nil }
      end = bound
    }
    if case .none = start, case .none = end { return nil }
    if case .instant(let first)? = start, case .instant(let last)? = end, last <= first { return nil }
    return DateRangeValue(start: start, end: end)
  }

  /// `2026-09-30T18:30Z`, `-7d` or `-1h`.
  static func parseBound(_ string: String) -> Bound? {
    if let minutes = parseInstant(string) { return .instant(minutes) }
    let bytes = Array(string.utf8)
    // A minus, a count, a unit.
    guard bytes.count >= 3, bytes[0] == 45 else { return nil }
    var count = 0
    for index in 1..<(bytes.count - 1) {
      let byte = bytes[index]
      guard byte >= 48 && byte <= 57 else { return nil }
      count = count * 10 + Int(byte - 48)
      if count > 100_000 { return nil }
    }
    guard count > 0 else { return nil }
    switch bytes[bytes.count - 1] {
    case 100: return .days(count)  // d
    case 104: return .hours(count)  // h
    default: return nil
    }
  }

  /// `yyyy-mm-ddTHH:MMZ` as minutes since the epoch.
  static func parseInstant(_ string: String) -> Int64? {
    let bytes = Array(string.utf8)
    guard bytes.count == 17, bytes[10] == 84, bytes[13] == 58, bytes[16] == 90 else { return nil }
    guard let day = CalendarDate.parse(stringSubstring(string, from: 0, to: 10)),
      let time = TimeOfDay.parse(stringSubstring(string, from: 11, to: 16))
    else { return nil }
    return Int64(day.dayNumber) * 1_440 + Int64(time.minutes)
  }

  /// `2026-09-30T18:30Z`.
  static func instantText(_ minutes: Int64) -> String {
    let dayNumber = minutes / 1_440 - (minutes % 1_440 < 0 ? 1 : 0)
    let time = minutes - dayNumber * 1_440
    return "\(CalendarDate(dayNumber: Int(dayNumber)).iso)T\(TimeOfDay(hour: Int(time / 60), minute: Int(time % 60)).text)Z"
  }

  /// As a URL carries it.
  public var param: String {
    "\(Self.text(start))..\(Self.text(end))"
  }

  private static func text(_ bound: Bound?) -> String {
    switch bound {
    case .none: return ""
    case .instant(let minutes)?: return instantText(minutes)
    case .days(let count)?: return "-\(count)d"
    case .hours(let count)?: return "-\(count)h"
    }
  }

  /// The reader's days `first` through `last`, either order, as the UTC
  /// moments that bound them; `last` nil leaves the end open.
  public static func fixed(_ first: CalendarDate, _ last: CalendarDate?) -> DateRangeValue {
    var lower = first
    var upper = last
    if let last, last.dayNumber < first.dayNumber {
      lower = last
      upper = first
    }
    return DateRangeValue(
      start: .instant(ViewerZone.epochMinutes(startOf: lower)),
      end: upper.map { .instant(ViewerZone.epochMinutes(startOf: $0.adding(days: 1))) })
  }

  /// Whether either end counts back from now.
  public var isRelative: Bool {
    switch start {
    case .days?, .hours?: return true
    default: break
    }
    switch end {
    case .days?, .hours?: return true
    default: return false
    }
  }

  // MARK: - Days

  /// The reader's first and last day the range covers, as a calendar marks
  /// them; nil at an open end—except that a range counting back from now
  /// runs to today, so a preset marks every day it covers.
  public func days(now: Int64 = ViewerZone.nowMinutes()) -> (start: CalendarDate?, end: CalendarDate?) {
    let today = ViewerZone.localDay(epochMinutes: now)
    let first: CalendarDate?
    switch start {
    case .none: first = nil
    case .instant(let minutes)?: first = ViewerZone.localDay(epochMinutes: minutes)
    case .days(let count)?: first = today.adding(days: -(count - 1))
    case .hours(let count)?: first = ViewerZone.localDay(epochMinutes: now - Int64(count) * 60)
    }
    let last: CalendarDate?
    switch end {
    case .none: last = isRelative ? today : nil
    // The end is the next day's first moment: its last day is the one before.
    case .instant(let minutes)?: last = ViewerZone.localDay(epochMinutes: minutes - 1)
    case .days(let count)?: last = today.adding(days: -(count - 1))
    case .hours(let count)?: last = ViewerZone.localDay(epochMinutes: now - Int64(count) * 60 - 1)
    }
    return (first, last)
  }

  /// Whether every covered day fits the picker's inclusive limits. An
  /// open end cannot fit a limit on that side; relative presets end today.
  func isWithin(min: CalendarDate?, max: CalendarDate?, now: Int64 = ViewerZone.nowMinutes()) -> Bool {
    let resolved = days(now: now)
    if let min {
      guard let first = resolved.start, first.dayNumber >= min.dayNumber else { return false }
    }
    if let max {
      guard let last = resolved.end, last.dayNumber <= max.dayNumber else { return false }
    }
    if let first = resolved.start, let last = resolved.end, first.dayNumber > last.dayNumber { return false }
    return true
  }

  // MARK: - Words

  /// "Oct 1–8, 2026", "Oct 1, 2026", "Since Oct 1, 2026", "Until Oct 8,
  /// 2026" (CalendarDate.rangeText, the reader's days), "Last 7 days",
  /// "Today", "Last hour".
  public var label: String {
    switch (start, end) {
    case (.days(let count)?, .none):
      return count == 1 ? "Today" : "Last \(count) days"
    case (.hours(let count)?, .none):
      return count == 1 ? "Last hour" : "Last \(count) hours"
    default:
      let (first, last) = days()
      return CalendarDate.rangeText(first, last)
    }
  }
}
