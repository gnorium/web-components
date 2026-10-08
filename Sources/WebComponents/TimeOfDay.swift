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

  /// The time `minutes` past midnight, wrapped into the day: a time moved
  /// into another zone may cross midnight either way.
  public init(minutes: Int) {
    let wrapped = ((minutes % 1_440) + 1_440) % 1_440
    self.init(hour: wrapped / 60, minute: wrapped % 60)
  }

  /// The hour on a 12-hour clock, 1 to 12.
  public var hour12: Int { hour % 12 == 0 ? 12 : hour % 12 }

  public var isPM: Bool { hour >= 12 }

  /// "9:05 AM", as the tables' "at" columns read.
  public var text12: String { "\(hour12):\(Self.twoDigits(minute)) \(isPM ? "PM" : "AM")" }

  /// From a 12-hour clock: 12 AM is midnight, 12 PM noon.
  public init(hour12: Int, minute: Int, pm: Bool) {
    self.init(hour: hour12 % 12 + (pm ? 12 : 0), minute: minute)
  }

  /// `7` → `07`.
  public static func twoDigits(_ value: Int) -> String {
    let clamped = value < 0 ? 0 : value % 100
    return String(decoding: [UInt8(48 + clamped / 10), UInt8(48 + clamped % 10)], as: UTF8.self)
  }
}

/// A span of the day as one URL value carries it: two UTC times of day,
/// `03:30Z..12:00Z` (9:00 AM–5:30 PM in India), either end open
/// (`03:30Z..`, `..12:00Z`). Both ends are whole minutes, the end's
/// included; an end before its start runs across midnight (`22:00Z..06:00Z`),
/// which a span moved into UTC often does. The reader picks and reads it in
/// their own clock (`local`, `fromLocal`, by ViewerZone's offset).
public struct TimeRangeValue: Sendable {
  /// UTC.
  public let start: TimeOfDay?
  public let end: TimeOfDay?

  public init(start: TimeOfDay?, end: TimeOfDay?) {
    self.start = start
    self.end = end
  }

  /// Reads `start..end`, each `HH:MMZ`; nil for anything else, or for a
  /// span open at both ends.
  public static func parse(_ string: String) -> TimeRangeValue? {
    let trimmed = stringTrim(string)
    guard let dots = stringIndexOf(trimmed, "..") else { return nil }
    let lower = stringSubstring(trimmed, from: 0, to: dots)
    let upper = stringSubstring(trimmed, from: dots + 2)
    var start: TimeOfDay?
    var end: TimeOfDay?
    if !stringIsEmpty(lower) {
      guard let time = utc(lower) else { return nil }
      start = time
    }
    if !stringIsEmpty(upper) {
      guard let time = utc(upper) else { return nil }
      end = time
    }
    if case .none = start, case .none = end { return nil }
    return TimeRangeValue(start: start, end: end)
  }

  /// `HH:MMZ`.
  static func utc(_ string: String) -> TimeOfDay? {
    let bytes = Array(string.utf8)
    guard bytes.count == 6, bytes[5] == 90 else { return nil }
    return TimeOfDay.parse(stringSubstring(string, from: 0, to: 5))
  }

  /// As a URL carries it: `03:30Z..12:00Z`.
  public var param: String {
    "\(start.map { "\($0.text)Z" } ?? "")..\(end.map { "\($0.text)Z" } ?? "")"
  }

  /// The span in the reader's clock.
  public var local: (start: TimeOfDay?, end: TimeOfDay?) {
    let offset = ViewerZone.offsetMinutes()
    return (start.map { TimeOfDay(minutes: $0.minutes + offset) }, end.map { TimeOfDay(minutes: $0.minutes + offset) })
  }

  /// A span picked in the reader's clock, carried in UTC.
  public static func fromLocal(start: TimeOfDay?, end: TimeOfDay?) -> TimeRangeValue {
    let offset = ViewerZone.offsetMinutes()
    return TimeRangeValue(
      start: start.map { TimeOfDay(minutes: $0.minutes - offset) },
      end: end.map { TimeOfDay(minutes: $0.minutes - offset) })
  }

  /// "9:00 AM–5:30 PM", "Since 9:00 AM", "Until 5:30 PM": the reader's
  /// clock, a closed en dash, as a range of days is written
  /// (CalendarDate.rangeText).
  public var label: String {
    let (first, last) = local
    if let first, let last { return "\(first.text12)–\(last.text12)" }
    if let first { return "Since \(first.text12)" }
    if let last { return "Until \(last.text12)" }
    return ""
  }

  /// Whether a UTC minute of the day falls in the span.
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
