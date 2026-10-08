import EmbeddedSwiftUtilities

/// A time of day to the minute, `HH:MM` on a 24-hour clock, with no day and
/// no zone: what a time input holds. Byte and integer work only, so the
/// client reads one as the server does.
public struct TimeOfDay: Sendable {
  /// 0 to 23.
  public let hour: Int
  /// 0 to 59.
  public let minute: Int

  public init(hour: Int, minute: Int) {
    self.hour = hour
    self.minute = minute
  }

  /// Reads `HH:MM`; nil for anything else.
  public static func parse(_ string: String) -> TimeOfDay? {
    let bytes = Array(stringTrim(string).utf8)
    guard bytes.count == 5, bytes[2] == 58 else { return nil }
    for index in [0, 1, 3, 4] where bytes[index] < 48 || bytes[index] > 57 { return nil }
    let hour = Int(bytes[0] - 48) * 10 + Int(bytes[1] - 48)
    let minute = Int(bytes[3] - 48) * 10 + Int(bytes[4] - 48)
    guard hour <= 23, minute <= 59 else { return nil }
    return TimeOfDay(hour: hour, minute: minute)
  }

  /// `09:05`.
  public var text: String { "\(Self.twoDigits(hour)):\(Self.twoDigits(minute))" }

  /// Minutes since midnight.
  public var minutes: Int { hour * 60 + minute }

  /// `7` → `07`.
  public static func twoDigits(_ value: Int) -> String {
    let clamped = value < 0 ? 0 : value % 100
    return String(decoding: [UInt8(48 + clamped / 10), UInt8(48 + clamped % 10)], as: UTF8.self)
  }
}

/// A span of the day as one URL value carries it: `09:00..17:30`, either end
/// open (`09:00..`, `..17:30`). Both ends are whole minutes, the end's
/// included; an end before its start runs across midnight (`22:00..06:00`).
public struct TimeRangeValue: Sendable {
  public let start: TimeOfDay?
  public let end: TimeOfDay?

  public init(start: TimeOfDay?, end: TimeOfDay?) {
    self.start = start
    self.end = end
  }

  /// Reads `start..end`; nil for anything else, or for a span open at both
  /// ends.
  public static func parse(_ string: String) -> TimeRangeValue? {
    let trimmed = stringTrim(string)
    guard let dots = stringIndexOf(trimmed, "..") else { return nil }
    let lower = stringSubstring(trimmed, from: 0, to: dots)
    let upper = stringSubstring(trimmed, from: dots + 2)
    var start: TimeOfDay?
    var end: TimeOfDay?
    if !stringIsEmpty(lower) {
      guard let time = TimeOfDay.parse(lower) else { return nil }
      start = time
    }
    if !stringIsEmpty(upper) {
      guard let time = TimeOfDay.parse(upper) else { return nil }
      end = time
    }
    if case .none = start, case .none = end { return nil }
    return TimeRangeValue(start: start, end: end)
  }

  /// As a URL carries it.
  public var param: String { "\(start?.text ?? "")..\(end?.text ?? "")" }

  /// "09:00–17:30", "Since 09:00", "Until 17:30"—a closed en dash, as a
  /// range of days is written (CalendarDate.rangeText)—the zone after it
  /// when one is named: "09:00–17:30 UTC".
  public func label(zone: String = "") -> String {
    let suffix = stringIsEmpty(zone) ? "" : " \(zone)"
    if let start, let end { return "\(start.text)–\(end.text)\(suffix)" }
    if let start { return "Since \(start.text)\(suffix)" }
    if let end { return "Until \(end.text)\(suffix)" }
    return ""
  }

  /// Whether a minute of the day falls in the span.
  public func contains(minutes: Int) -> Bool {
    switch (start, end) {
    case (.some(let first), .some(let last)):
      return first.minutes <= last.minutes
        ? minutes >= first.minutes && minutes <= last.minutes
        : minutes >= first.minutes || minutes <= last.minutes
    case (.some(let first), .none): return minutes >= first.minutes
    case (.none, .some(let last)): return minutes <= last.minutes
    case (.none, .none): return true
    }
  }
}
