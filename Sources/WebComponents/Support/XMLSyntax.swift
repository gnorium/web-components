/// XML's syntax, as a code block colors it (`CodeSyntax`): where each tag,
/// name, prefix, attribute, value, reference, comment, instruction and CDATA
/// section stands in a text.
///
/// Read byte by byte in one pass, and counted in UTF-16 code units, as a DOM
/// `Range` counts a text node: the same code runs on the server and in the
/// browser, where Embedded Swift carries no Unicode tables.
public enum XMLSyntax {
  public typealias Kind = CodeSyntax.Kind
  public typealias Token = CodeSyntax.Token

  /// The colored stretches of `text`, in order, by XML's grammar: a tag's
  /// marks, its name, its attributes' names and values, each name's
  /// namespace prefix apart; comments, processing instructions,
  /// declarations, CDATA sections; and entity and character references in
  /// text and in values. Text between tags is left plain.
  public static func tokens(_ text: [UInt8]) -> [Token] {
    var units = CodeSyntax.Units()
    var out: [Token] = []
    func add(_ kind: Kind, _ from: Int, _ to: Int) {
      if to > from { out.append(Token(kind: kind, start: units.at(from, in: text), end: units.at(to, in: text))) }
    }
    /// A name of `kind`, its prefix (`tei:`, `xml:`) apart.
    func addName(_ kind: Kind, _ from: Int, _ to: Int) {
      var colon = from
      while colon < to, text[colon] != 0x3A { colon += 1 }
      if colon > from, colon < to - 1 {
        add(.prefix, from, colon + 1)
        add(kind, colon + 1, to)
      } else {
        add(kind, from, to)
      }
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
    /// Where a reference that opens at `index` (`&`) ends, past its `;`;
    /// nil where `&` opens none (a name or `#` digits, then `;`).
    func reference(at index: Int) -> Int? {
      var cursor = index + 1
      while cursor < text.count, cursor - index <= 32 {
        let byte = text[cursor]
        if byte == 0x3B { return cursor > index + 1 ? cursor + 1 : nil }
        guard byte == 0x23 || byte == 0x3A || byte == 0x5F || byte == 0x2D || byte == 0x2E
          || (byte >= 0x30 && byte <= 0x39) || (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A)
          || byte >= 0x80
        else { return nil }
        cursor += 1
      }
      return nil
    }
    /// A stretch of `kind` from `from` to `to`, its references apart.
    func addWithReferences(_ kind: Kind, _ from: Int, _ to: Int) {
      var start = from
      var cursor = from
      while cursor < to {
        if text[cursor] == 0x26, let end = reference(at: cursor), end <= to {
          add(kind, start, cursor)
          add(.entity, cursor, end)
          cursor = end
          start = end
        } else {
          cursor += 1
        }
      }
      add(kind, start, to)
    }

    var index = 0
    while index < text.count {
      guard text[index] == 0x3C else {
        // Text: plain, its references colored.
        if text[index] == 0x26, let end = reference(at: index) {
          add(.entity, index, end)
          index = end
        } else {
          index += 1
        }
        continue
      }
      if starts("<!--", at: index) {
        let end = past("-->", from: index + 4)
        add(.comment, index, end)
        index = end
      } else if starts("<![CDATA[", at: index) {
        let end = past("]]>", from: index + 9)
        add(.cdata, index, end)
        index = end
      } else if starts("<?", at: index) {
        let end = past("?>", from: index + 2)
        add(.pi, index, end)
        index = end
      } else if starts("<!", at: index) {
        let end = past(">", from: index + 2)
        add(.pi, index, end)
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
        addName(.name, nameStart, cursor)
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
            addWithReferences(.value, cursor, end)
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
            addName(.attribute, start, cursor)
          }
        }
        index = cursor
      }
    }
    return out
  }
}
