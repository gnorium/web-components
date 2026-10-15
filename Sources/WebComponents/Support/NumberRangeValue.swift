import EmbeddedSwiftUtilities

/// A range of numbers as one URL value carries it: `1000..5000`, both ends
/// included; either end may be open (`..5000`, `1000..`). Each end is a
/// decimal as typed—`0.05`, `12`, `-3.5`—with no exponent and no grouping,
/// so a cost reads to the cent and below.
///
/// The grammar is byte work only, so the client reads one as the server
/// does (the server's `NumberRangeFilter` reads the same grammar).
public struct NumberRangeValue: Sendable {
  /// Each end as written; nil where it is open.
  public let start: String?
  public let end: String?

  public init(start: String?, end: String?) {
    self.start = start
    self.end = end
  }

  /// Reads `start..end`; nil for anything else, for an end below its start,
  /// or for a range open at both ends.
  public static func parse(_ string: String) -> NumberRangeValue? {
    let trimmed = stringTrim(string)
    guard let dots = stringIndexOf(trimmed, "..") else { return nil }
    let lower = stringTrim(stringSubstring(trimmed, from: 0, to: dots))
    let upper = stringTrim(stringSubstring(trimmed, from: dots + 2))
    var start: String?
    var end: String?
    if !stringIsEmpty(lower) {
      guard isNumber(lower) else { return nil }
      start = lower
    }
    if !stringIsEmpty(upper) {
      guard isNumber(upper) else { return nil }
      end = upper
    }
    if case .none = start, case .none = end { return nil }
    if let start, let end, let first = number(start), let last = number(end), last < first { return nil }
    return NumberRangeValue(start: start, end: end)
  }

  /// The range two typed ends make: `start..end`, an empty end left open;
  /// nil when both are empty.
  public static func from(start: String, end: String) -> NumberRangeValue? {
    let first = stringTrim(start)
    let last = stringTrim(end)
    if stringIsEmpty(first) && stringIsEmpty(last) { return nil }
    return NumberRangeValue(start: stringIsEmpty(first) ? nil : first, end: stringIsEmpty(last) ? nil : last)
  }

  /// As a URL carries it.
  public var param: String { "\(start ?? "")..\(end ?? "")" }

  /// As its field reads: "1000–5000", "From 1000", "Up to 5000"—a closed en
  /// dash, as a range of days is written.
  public var label: String {
    if let start, let end { return "\(start)–\(end)" }
    if let start { return "From \(start)" }
    if let end { return "Up to \(end)" }
    return ""
  }

  /// Whether `text` is a decimal: an optional minus, digits, and at most one
  /// point among them, with a digit somewhere.
  public static func isNumber(_ text: String) -> Bool {
    let bytes = Array(text.utf8)
    guard !bytes.isEmpty, bytes.count <= 32 else { return false }
    var digits = 0
    var points = 0
    for (index, byte) in bytes.enumerated() {
      if byte >= 48 && byte <= 57 {
        digits += 1
      } else if byte == 46 {
        points += 1
        if points > 1 { return false }
      } else if byte == 45 {
        if index != 0 { return false }
      } else {
        return false
      }
    }
    return digits > 0
  }

  /// A decimal's value; nil for one that is not (`isNumber`).
  public static func number(_ text: String) -> Double? {
    guard isNumber(text) else { return nil }
    var whole = 0.0
    var fraction = 0.0
    var scale = 1.0
    var negative = false
    var afterPoint = false
    for byte in text.utf8 {
      switch byte {
      case 45: negative = true
      case 46: afterPoint = true
      default:
        let digit = Double(Int(byte - 48))
        if afterPoint {
          scale /= 10
          fraction += digit * scale
        } else {
          whole = whole * 10 + digit
        }
      }
    }
    let value = whole + fraction
    return negative ? -value : value
  }
}
