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
}
