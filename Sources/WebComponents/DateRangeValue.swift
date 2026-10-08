import EmbeddedSwiftUtilities

/// A range of days as one URL value carries it, in one of two forms:
///
/// - fixed: `2026-10-01..2026-10-08`, either end open (`2026-10-01..`,
///   `..2026-10-08`); a start equal to its end is that one day;
/// - relative: `-7d..`, the seven days that end today; `-1d..`, today;
///   `-1h..`, the last hour. A relative range stays relative, so a bookmarked
///   "Last 7 days" still means the last seven days when it is opened later.
///
/// Days are UTC days (`CalendarDate.utcToday()`). Byte and integer work only,
/// so the client reads one as the server does.
public struct DateRangeValue: Sendable {
  public enum Bound: Sendable {
    case day(CalendarDate)
    /// The N days that end today: as a start, the day N − 1 days back; as an
    /// end, the same day, whole.
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

  /// Reads `start..end`; nil for anything else, for an end before its start,
  /// or for a range open at both ends.
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
    if case .day(let first)? = start, case .day(let last)? = end, last.dayNumber < first.dayNumber {
      return nil
    }
    return DateRangeValue(start: start, end: end)
  }

  /// `2026-10-01`, `-7d` or `-1h`.
  static func parseBound(_ string: String) -> Bound? {
    if let day = CalendarDate.parse(string) { return .day(day) }
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

  /// As a URL carries it.
  public var param: String {
    "\(Self.text(start))..\(Self.text(end))"
  }

  private static func text(_ bound: Bound?) -> String {
    switch bound {
    case .none: return ""
    case .day(let day)?: return day.iso
    case .days(let count)?: return "-\(count)d"
    case .hours(let count)?: return "-\(count)h"
    }
  }

  /// A fixed range of days, the earlier first.
  public static func fixed(_ first: CalendarDate, _ second: CalendarDate?) -> DateRangeValue {
    guard let second else { return DateRangeValue(start: .day(first), end: nil) }
    return second.dayNumber < first.dayNumber
      ? DateRangeValue(start: .day(second), end: .day(first))
      : DateRangeValue(start: .day(first), end: .day(second))
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

  /// The first and last day the range covers, as a calendar marks them;
  /// nil at an open end—except that a range counting back from now runs to
  /// today, so a preset marks every day it covers.
  public func days(today: CalendarDate) -> (start: CalendarDate?, end: CalendarDate?) {
    let first = Self.day(start, today: today)
    if case .none = end, isRelative { return (first, today) }
    return (first, Self.day(end, today: today))
  }

  private static func day(_ bound: Bound?, today: CalendarDate) -> CalendarDate? {
    switch bound {
    case .none: return nil
    case .day(let day)?: return day
    case .days(let count)?: return today.adding(days: -(count - 1))
    case .hours(let count)?: return today.adding(days: -(count / 24))
    }
  }

  // MARK: - Words

  /// "Oct 1–8, 2026", "Oct 1, 2026", "Since Oct 1, 2026", "Until Oct 8,
  /// 2026" (CalendarDate.rangeText), "Last 7 days", "Today", "Last hour".
  public var label: String {
    switch (start, end) {
    case (.days(let count)?, .none):
      return count == 1 ? "Today" : "Last \(count) days"
    case (.hours(let count)?, .none):
      return count == 1 ? "Last hour" : "Last \(count) hours"
    case (.day(let first)?, .day(let last)?):
      return CalendarDate.rangeText(first, last)
    case (.day(let first)?, .none):
      return CalendarDate.rangeText(first, nil)
    case (.none, .day(let last)?):
      return CalendarDate.rangeText(nil, last)
    case (.some(let first), .none):
      return "Since \(Self.words(first))"
    case (.none, .some(let last)):
      return "Until \(Self.words(last))"
    case (.some(let first), .some(let last)):
      return "\(Self.words(first))–\(Self.words(last))"
    case (.none, .none):
      return ""
    }
  }

  private static func words(_ bound: Bound) -> String {
    switch bound {
    case .day(let day): return day.display
    case .days(let count):
      return count == 1 ? "today" : count == 2 ? "yesterday" : "\(count - 1) days ago"
    case .hours(let count):
      return count == 1 ? "an hour ago" : "\(count) hours ago"
    }
  }
}
