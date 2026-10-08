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

/// A span of the day as one URL value carries it: wall-clock times and the
/// IANA zone they were set in, RFC 9557's annotation—`09:00..17:30[America/New_York]`.
/// A time of day is not an instant: "9 AM in New York" is 13:00 UTC in
/// summer and 14:00 in winter, so the zone travels with it and each moment
/// is asked in that zone on its own date (the server: `TimeRangeFilter`).
/// Either end may be open (`09:00..[Asia/Kolkata]`); an end before its start
/// runs across midnight; the end's minute is included.
public struct TimeRangeValue: Sendable {
  /// Wall-clock times in `zone`.
  public let start: TimeOfDay?
  public let end: TimeOfDay?
  /// The IANA zone they were set in.
  public let zone: String

  public init(start: TimeOfDay?, end: TimeOfDay?, zone: String) {
    self.start = start
    self.end = end
    self.zone = zone
  }

  /// Reads `start..end[Zone/Name]`; nil for anything else, for no zone, or
  /// for a span open at both ends.
  public static func parse(_ string: String) -> TimeRangeValue? {
    let trimmed = stringTrim(string)
    guard let bracket = stringIndexOf(trimmed, "["), stringEndsWith(trimmed, "]") else { return nil }
    let zone = stringSubstring(trimmed, from: bracket + 1, to: trimmed.utf8.count - 1)
    guard isZoneName(zone) else { return nil }
    let span = stringSubstring(trimmed, from: 0, to: bracket)
    guard let dots = stringIndexOf(span, "..") else { return nil }
    let lower = stringSubstring(span, from: 0, to: dots)
    let upper = stringSubstring(span, from: dots + 2)
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
    return TimeRangeValue(start: start, end: end, zone: zone)
  }

  /// An IANA name's characters: letters, digits, `/`, `_`, `+`, `-`.
  static func isZoneName(_ zone: String) -> Bool {
    let bytes = Array(zone.utf8)
    guard !bytes.isEmpty, bytes.count <= 64 else { return false }
    for byte in bytes {
      let letter = (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122)
      let digit = byte >= 48 && byte <= 57
      guard letter || digit || byte == 47 || byte == 95 || byte == 43 || byte == 45 else { return false }
    }
    return true
  }

  /// As a URL carries it: `09:00..17:30[America/New_York]`.
  public var param: String { "\(start?.text ?? "")..\(end?.text ?? "")[\(zone)]" }

  /// A span picked in the reader's clock, carried with the reader's zone.
  public static func fromLocal(start: TimeOfDay?, end: TimeOfDay?) -> TimeRangeValue {
    TimeRangeValue(start: start, end: end, zone: ViewerZone.name())
  }

  /// Whether it was set in the reader's own zone.
  public var isReadersZone: Bool { stringEquals(zone, ViewerZone.name()) }

  /// The span on the reader's clock today: its own times when it was set in
  /// the reader's zone; else each end moved through today's moment in its
  /// zone.
  public var local: (start: TimeOfDay?, end: TimeOfDay?) {
    if isReadersZone { return (start, end) }
    let today = ViewerZone.today()
    let move = { (time: TimeOfDay) -> TimeOfDay in
      let moment = ViewerZone.epochMinutes(day: today, minutes: time.minutes, zone: zone)
      return TimeOfDay(minutes: ViewerZone.wallMinutes(epochMinutes: moment, zone: ViewerZone.name()))
    }
    return (start.map(move), end.map(move))
  }

  /// "9:00 AM–5:30 PM", "Since 9:00 AM", "Until 5:30 PM": the span on the
  /// reader's clock, a closed en dash as a range of days is written. One set
  /// in another zone is shown converted; the URL keeps its own zone.
  public var label: String {
    let (first, last) = local
    return Self.words(first, last)
  }

  static func words(_ first: TimeOfDay?, _ last: TimeOfDay?) -> String {
    if let first, let last { return "\(first.text12)–\(last.text12)" }
    if let first { return "Since \(first.text12)" }
    if let last { return "Until \(last.text12)" }
    return ""
  }

  /// Whether a wall-clock minute of the day (in `zone`) falls in the span.
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
