import EmbeddedSwiftUtilities

#if SERVER
  import Foundation
#endif
#if CLIENT
  import WebAPIs
#endif

/// A day on the proleptic Gregorian calendar, with no time and no zone: what
/// a date field holds. Integer arithmetic only, so the client can use it
/// without Unicode or Foundation.
public struct CalendarDate: Sendable {
  public let year: Int
  /// 1 for January.
  public let month: Int
  /// 1 for the first of the month.
  public let day: Int

  public init(year: Int, month: Int, day: Int) {
    self.year = year
    self.month = month
    self.day = day
  }

  // MARK: - Names (the UI is English)

  public static let monthNames: [String] = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ]
  public static let monthAbbreviations: [String] = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ]
  /// Indexed by weekday, 0 for Sunday.
  public static let weekdayNames: [String] = [
    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
  ]
  /// Two letters, as a calendar's column heads.
  public static let weekdayAbbreviations: [String] = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

  // MARK: - Reading and writing

  /// Reads `yyyy-mm-dd`; nil for anything else, or for a day the month lacks.
  public static func parse(_ string: String) -> CalendarDate? {
    let bytes = Array(string.utf8)
    guard bytes.count == 10, bytes[4] == 45, bytes[7] == 45 else { return nil }
    func number(_ from: Int, _ to: Int) -> Int? {
      var value = 0
      for index in from..<to {
        let byte = bytes[index]
        guard byte >= 48 && byte <= 57 else { return nil }
        value = value * 10 + Int(byte - 48)
      }
      return value
    }
    guard let year = number(0, 4), let month = number(5, 7), let day = number(8, 10),
      month >= 1, month <= 12, day >= 1, day <= daysInMonth(year: year, month: month)
    else { return nil }
    return CalendarDate(year: year, month: month, day: day)
  }

  /// `yyyy-mm-dd`, what a form submits.
  public var iso: String {
    "\(Self.padded(year, 4))-\(Self.padded(month, 2))-\(Self.padded(day, 2))"
  }

  /// "Sep 25, 2026".
  public var display: String {
    "\(Self.monthAbbreviations[month - 1]) \(day), \(year)"
  }

  /// "Friday, September 25, 2026".
  public var spoken: String {
    "\(Self.weekdayNames[weekday]), \(Self.monthNames[month - 1]) \(day), \(year)"
  }

  /// "September 2026".
  public var monthTitle: String {
    "\(Self.monthNames[month - 1]) \(year)"
  }

  private static func padded(_ value: Int, _ width: Int) -> String {
    var digits: [UInt8] = []
    var rest = value < 0 ? -value : value
    repeat {
      digits.append(UInt8(48 + rest % 10))
      rest /= 10
    } while rest > 0
    while digits.count < width { digits.append(48) }
    return String(decoding: digits.reversed(), as: UTF8.self)
  }

  // MARK: - Arithmetic

  public static func isLeapYear(_ year: Int) -> Bool {
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
  }

  public static func daysInMonth(year: Int, month: Int) -> Int {
    switch month {
    case 2: return isLeapYear(year) ? 29 : 28
    case 4, 6, 9, 11: return 30
    default: return 31
    }
  }

  /// Days since 1970-01-01 (Hinnant's days-from-civil).
  public var dayNumber: Int {
    let y = month <= 2 ? year - 1 : year
    let era = (y >= 0 ? y : y - 399) / 400
    let yearOfEra = y - era * 400
    let monthIndex = month > 2 ? month - 3 : month + 9
    let dayOfYear = (153 * monthIndex + 2) / 5 + day - 1
    let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
    return era * 146097 + dayOfEra - 719468
  }

  /// The day a number of days from 1970-01-01 names (Hinnant's civil-from-days).
  public init(dayNumber: Int) {
    let z = dayNumber + 719468
    let era = (z >= 0 ? z : z - 146096) / 146097
    let dayOfEra = z - era * 146097
    let yearOfEra = (dayOfEra - dayOfEra / 1460 + dayOfEra / 36524 - dayOfEra / 146096) / 365
    let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
    let monthIndex = (5 * dayOfYear + 2) / 153
    let day = dayOfYear - (153 * monthIndex + 2) / 5 + 1
    let month = monthIndex < 10 ? monthIndex + 3 : monthIndex - 9
    let year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0)
    self.init(year: year, month: month, day: day)
  }

  /// 0 for Sunday. 1970-01-01 was a Thursday.
  public var weekday: Int {
    let remainder = (dayNumber + 4) % 7
    return remainder < 0 ? remainder + 7 : remainder
  }

  public func adding(days: Int) -> CalendarDate {
    CalendarDate(dayNumber: dayNumber + days)
  }

  /// The same day a number of months on, or the month's last day when it is
  /// shorter (Jan 31 + 1 month is Feb 28).
  public func adding(months: Int) -> CalendarDate {
    let index = year * 12 + (month - 1) + months
    let newYear = index >= 0 ? index / 12 : (index - 11) / 12
    let newMonth = index - newYear * 12 + 1
    let newDay = Swift.min(day, Self.daysInMonth(year: newYear, month: newMonth))
    return CalendarDate(year: newYear, month: newMonth, day: newDay)
  }

  public func isSameDay(as other: CalendarDate) -> Bool {
    year == other.year && month == other.month && day == other.day
  }

  public func isSameMonth(as other: CalendarDate) -> Bool {
    year == other.year && month == other.month
  }

  /// This day held within the bounds given.
  public func clamped(min: CalendarDate?, max: CalendarDate?) -> CalendarDate {
    if let min, dayNumber < min.dayNumber { return min }
    if let max, dayNumber > max.dayNumber { return max }
    return self
  }

  public func isWithin(min: CalendarDate?, max: CalendarDate?) -> Bool {
    if let min, dayNumber < min.dayNumber { return false }
    if let max, dayNumber > max.dayNumber { return false }
    return true
  }

  // MARK: - Today

  /// Today where the reader is: the browser's zone on the client, the
  /// server's on the server (a page's first render, which the client redraws).
  public static func today() -> CalendarDate {
    #if CLIENT
      let now = JSDate()
      return CalendarDate(year: now.fullYear, month: now.month + 1, day: now.date)
    #else
      let parts = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: Date())
      return CalendarDate(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    #endif
  }
}
