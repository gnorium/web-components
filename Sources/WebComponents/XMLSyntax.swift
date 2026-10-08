/// XML's syntax, as a code block colors it: where each tag, name, attribute,
/// value, comment and declaration stands in a text. The stretches are those
/// highlight.js colors in a `CodeView` (`hljs-tag`, `-name`, `-attr`,
/// `-string`, `-comment`, `-meta`), so an editor colored by them reads as
/// the block does.
///
/// Read byte by byte, and counted in UTF-16 code units, as a DOM `Range`
/// counts a text node: the same code runs on the server and in the browser,
/// where Embedded Swift carries no Unicode tables.
public enum XMLSyntax {
  public enum Kind: Int, Sendable, CaseIterable {
    /// `<`, `</`, `>`, `/>`.
    case tag
    /// An element's name.
    case name
    /// An attribute's name.
    case attribute
    /// An attribute's value, its quotes with it.
    case string
    /// `<!-- … -->`.
    case comment
    /// `<?xml … ?>`, `<!DOCTYPE …>`.
    case meta

    /// The highlight's name: what a `::highlight()` rule colors.
    public var highlightName: String {
      switch self {
      case .tag: return "code-tag"
      case .name: return "code-name"
      case .attribute: return "code-attr"
      case .string: return "code-string"
      case .comment: return "code-comment"
      case .meta: return "code-meta"
      }
    }
  }

  public struct Token: Sendable, Equatable {
    public let kind: Kind
    /// Half-open, in UTF-16 code units.
    public let start: Int
    public let end: Int
  }

  /// The colored stretches of `text`, in order. Text outside a tag—and a
  /// CDATA section's—is left plain.
  public static func tokens(_ text: [UInt8]) -> [Token] {
    // Where each byte starts, in UTF-16 code units.
    var units = [Int](repeating: 0, count: text.count + 1)
    var count = 0
    for (index, byte) in text.enumerated() {
      units[index] = count
      if byte & 0xC0 != 0x80 { count += byte >= 0xF0 ? 2 : 1 }
    }
    units[text.count] = count

    var out: [Token] = []
    func add(_ kind: Kind, _ from: Int, _ to: Int) {
      if to > from { out.append(Token(kind: kind, start: units[from], end: units[to])) }
    }
    func starts(_ prefix: StaticString, at index: Int) -> Bool {
      let length = prefix.utf8CodeUnitCount
      guard index + length <= text.count else { return false }
      var offset = 0
      while offset < length {
        if text[index + offset] != prefix.utf8Start[offset] { return false }
        offset += 1
      }
      return true
    }
    /// The index just past `end`, from `index`; the text's end without it.
    func past(_ end: StaticString, from index: Int) -> Int {
      var cursor = index
      while cursor < text.count {
        if starts(end, at: cursor) { return cursor + end.utf8CodeUnitCount }
        cursor += 1
      }
      return text.count
    }
    func isSpace(_ byte: UInt8) -> Bool { byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D }

    var index = 0
    while index < text.count {
      guard text[index] == 0x3C else {
        index += 1
        continue
      }
      if starts("<!--", at: index) {
        let end = past("-->", from: index + 4)
        add(.comment, index, end)
        index = end
      } else if starts("<![CDATA[", at: index) {
        index = past("]]>", from: index + 9)
      } else if starts("<?", at: index) {
        let end = past("?>", from: index + 2)
        add(.meta, index, end)
        index = end
      } else if starts("<!", at: index) {
        let end = past(">", from: index + 2)
        add(.meta, index, end)
        index = end
      } else {
        // A tag: its opening mark, its name, its attributes, its close.
        let mark = index + (starts("</", at: index) ? 2 : 1)
        add(.tag, index, mark)
        var cursor = mark
        let nameStart = cursor
        while cursor < text.count, !isSpace(text[cursor]), text[cursor] != 0x2F, text[cursor] != 0x3E,
          text[cursor] != 0x3C
        {
          cursor += 1
        }
        add(.name, nameStart, cursor)
        while cursor < text.count {
          let byte = text[cursor]
          if byte == 0x3E {
            add(.tag, cursor, cursor + 1)
            cursor += 1
            break
          }
          if starts("/>", at: cursor) {
            add(.tag, cursor, cursor + 2)
            cursor += 2
            break
          }
          // A tag left unfinished: what follows is read afresh.
          if byte == 0x3C { break }
          if byte == 0x22 || byte == 0x27 {
            var end = cursor + 1
            while end < text.count, text[end] != byte { end += 1 }
            end = min(end + 1, text.count)
            add(.string, cursor, end)
            cursor = end
          } else if isSpace(byte) || byte == 0x3D || byte == 0x2F {
            cursor += 1
          } else {
            let start = cursor
            while cursor < text.count, !isSpace(text[cursor]), text[cursor] != 0x3D, text[cursor] != 0x3E,
              text[cursor] != 0x3C, !starts("/>", at: cursor)
            {
              cursor += 1
            }
            add(.attribute, start, cursor)
          }
        }
        index = cursor
      }
    }
    return out
  }
}
