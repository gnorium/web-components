/// JSON's syntax, as a code block colors it (`CodeSyntax`): an object's
/// keys in the attribute role, strings in the string role, numbers indigo,
/// `true`, `false` and `null` as keywords; braces, brackets, commas and
/// colons the text's own.
///
/// Read byte by byte in one pass, forgiving: a tool call's JSON is preceded
/// by its name, and a result may be text, so a bare word stays plain and a
/// string left open ends at its line's end.
public enum JSONSyntax {
  public typealias Kind = CodeSyntax.Kind
  public typealias Token = CodeSyntax.Token

  public static func tokens(_ text: [UInt8]) -> [Token] {
    var units = CodeSyntax.Units()
    var out: [Token] = []
    func add(_ kind: Kind, _ from: Int, _ to: Int) {
      if to > from { out.append(Token(kind: kind, start: units.at(from, in: text), end: units.at(to, in: text))) }
    }
    func isSpace(_ byte: UInt8) -> Bool { byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D }
    func isDigit(_ byte: UInt8) -> Bool { byte >= 0x30 && byte <= 0x39 }
    func isWord(_ byte: UInt8) -> Bool {
      isDigit(byte) || (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A) || byte == 0x5F
        || byte == 0x24 || byte >= 0x80
    }
    func equals(_ from: Int, _ to: Int, _ word: StaticString) -> Bool {
      guard to - from == word.utf8CodeUnitCount else { return false }
      var offset = 0
      while offset < to - from {
        if text[from + offset] != word.utf8Start[offset] { return false }
        offset += 1
      }
      return true
    }

    var index = 0
    while index < text.count {
      let byte = text[index]
      if byte == 0x22 {
        // A string: to its closing quote, past escapes; or its line's end.
        var end = index + 1
        while end < text.count, text[end] != 0x22, text[end] != 0x0A {
          end += text[end] == 0x5C ? 2 : 1
        }
        end = min(end < text.count && text[end] == 0x22 ? end + 1 : end, text.count)
        // A key when a colon follows it.
        var next = end
        while next < text.count, isSpace(text[next]) { next += 1 }
        add(next < text.count && text[next] == 0x3A ? .attribute : .value, index, end)
        index = end
      } else if isDigit(byte) || (byte == 0x2D && index + 1 < text.count && isDigit(text[index + 1])) {
        var end = index + 1
        while end < text.count,
          isDigit(text[end]) || text[end] == 0x2E || text[end] == 0x65 || text[end] == 0x45
            || ((text[end] == 0x2B || text[end] == 0x2D) && (text[end - 1] == 0x65 || text[end - 1] == 0x45))
        {
          end += 1
        }
        add(.prefix, index, end)
        index = end
      } else if isWord(byte) {
        var end = index + 1
        while end < text.count, isWord(text[end]) { end += 1 }
        if equals(index, end, "true") || equals(index, end, "false") || equals(index, end, "null") {
          add(.name, index, end)
        }
        index = end
      } else {
        index += 1
      }
    }
    return out
  }
  /// Whether `text[from..<to]` is one JSON value, white space around it, as
  /// RFC 8259 reads it: strict where `tokens` forgives, so a reader that
  /// colors text as JSON only where it is (`ChatTemplateSyntax`) asks first.
  /// Nesting deeper than 512 is refused rather than read.
  public static func accepts(_ text: [UInt8], from: Int, to: Int) -> Bool {
    var reader = Acceptor(text: text, index: from, end: to)
    reader.space()
    guard reader.value(depth: 0) else { return false }
    reader.space()
    return reader.index == to
  }

  private struct Acceptor {
    let text: [UInt8]
    var index: Int
    let end: Int

    func isDigit(_ byte: UInt8) -> Bool { byte >= 0x30 && byte <= 0x39 }
    func isHex(_ byte: UInt8) -> Bool {
      isDigit(byte) || (byte >= 0x41 && byte <= 0x46) || (byte >= 0x61 && byte <= 0x66)
    }

    mutating func space() {
      while index < end, text[index] == 0x20 || text[index] == 0x09 || text[index] == 0x0A || text[index] == 0x0D {
        index += 1
      }
    }

    mutating func literal(_ word: StaticString) -> Bool {
      let length = word.utf8CodeUnitCount
      guard index + length <= end else { return false }
      var offset = 0
      while offset < length {
        if text[index + offset] != word.utf8Start[offset] { return false }
        offset += 1
      }
      index += length
      return true
    }

    mutating func digits() -> Bool {
      let start = index
      while index < end, isDigit(text[index]) { index += 1 }
      return index > start
    }

    mutating func number() -> Bool {
      if index < end, text[index] == 0x2D { index += 1 }
      guard index < end, isDigit(text[index]) else { return false }
      if text[index] == 0x30 { index += 1 } else { _ = digits() }
      if index < end, text[index] == 0x2E {
        index += 1
        guard digits() else { return false }
      }
      if index < end, text[index] == 0x65 || text[index] == 0x45 {
        index += 1
        if index < end, text[index] == 0x2B || text[index] == 0x2D { index += 1 }
        guard digits() else { return false }
      }
      return true
    }

    mutating func string() -> Bool {
      guard index < end, text[index] == 0x22 else { return false }
      index += 1
      while index < end {
        let byte = text[index]
        if byte == 0x22 {
          index += 1
          return true
        }
        if byte < 0x20 { return false }
        if byte == 0x5C {
          guard index + 1 < end else { return false }
          let escaped = text[index + 1]
          if escaped == 0x75 {
            guard index + 6 <= end, isHex(text[index + 2]), isHex(text[index + 3]), isHex(text[index + 4]),
              isHex(text[index + 5])
            else { return false }
            index += 6
            continue
          }
          // `"`, `\`, `/`, b, f, n, r, t.
          guard escaped == 0x22 || escaped == 0x5C || escaped == 0x2F || escaped == 0x62 || escaped == 0x66
            || escaped == 0x6E || escaped == 0x72 || escaped == 0x74
          else { return false }
          index += 2
          continue
        }
        index += 1
      }
      return false
    }

    mutating func value(depth: Int) -> Bool {
      guard index < end, depth < 512 else { return false }
      let byte = text[index]
      if byte == 0x7B {
        // An object: `"key": value`, comma-separated.
        index += 1
        space()
        if index < end, text[index] == 0x7D {
          index += 1
          return true
        }
        while true {
          guard string() else { return false }
          space()
          guard index < end, text[index] == 0x3A else { return false }
          index += 1
          space()
          guard value(depth: depth + 1) else { return false }
          space()
          guard index < end else { return false }
          if text[index] == 0x2C {
            index += 1
            space()
            continue
          }
          guard text[index] == 0x7D else { return false }
          index += 1
          return true
        }
      }
      if byte == 0x5B {
        // An array: values, comma-separated.
        index += 1
        space()
        if index < end, text[index] == 0x5D {
          index += 1
          return true
        }
        while true {
          guard value(depth: depth + 1) else { return false }
          space()
          guard index < end else { return false }
          if text[index] == 0x2C {
            index += 1
            space()
            continue
          }
          guard text[index] == 0x5D else { return false }
          index += 1
          return true
        }
      }
      if byte == 0x22 { return string() }
      if byte == 0x74 { return literal("true") }
      if byte == 0x66 { return literal("false") }
      if byte == 0x6E { return literal("null") }
      return number()
    }
  }
}
