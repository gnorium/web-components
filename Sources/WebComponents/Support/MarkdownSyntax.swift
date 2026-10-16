/// Markdown's syntax, as a code block colors it (`CodeSyntax`): a heading,
/// its `#` with it, as a keyword; emphasis marks (`*`, `**`, `_`) as
/// preprocessor marks; code, inline or fenced, as literal text; a link's or
/// image's URL indigo; list, quote and rule marks as characters; HTML
/// comments gray; link text and prose the text's own. A fence that names
/// XML or JSON is read by that language's grammar inside its marks.
///
/// Read line by line in one pass, by CommonMark's shapes but forgiving:
/// emphasis is colored only where its closing run stands later on the line,
/// so a `snake_case` name or `2 * 3` stays plain.
public enum MarkdownSyntax {
  public typealias Kind = CodeSyntax.Kind
  public typealias Token = CodeSyntax.Token

  public static func tokens(_ text: [UInt8]) -> [Token] {
    var units = CodeSyntax.Units()
    var out: [Token] = []
    func add(_ kind: Kind, _ from: Int, _ to: Int) {
      if to > from { out.append(Token(kind: kind, start: units.at(from, in: text), end: units.at(to, in: text))) }
    }
    func lineEnd(_ index: Int) -> Int {
      var end = index
      while end < text.count, text[end] != 0x0A { end += 1 }
      return end
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
    func isSpace(_ byte: UInt8) -> Bool { byte == 0x20 || byte == 0x09 }
    func isWord(_ byte: UInt8) -> Bool {
      (byte >= 0x30 && byte <= 0x39) || (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A)
        || byte >= 0x80
    }
    func lower(_ byte: UInt8) -> UInt8 { byte >= 0x41 && byte <= 0x5A ? byte + 0x20 : byte }
    /// Whether `from..<to` spells `word`, in any case.
    func spells(_ from: Int, _ to: Int, _ word: StaticString) -> Bool {
      guard to - from == word.utf8CodeUnitCount else { return false }
      var offset = 0
      while offset < to - from {
        if lower(text[from + offset]) != word.utf8Start[offset] { return false }
        offset += 1
      }
      return true
    }
    /// The run of `byte` from `index`: where it ends.
    func run(of byte: UInt8, from index: Int, to limit: Int) -> Int {
      var end = index
      while end < limit, text[end] == byte { end += 1 }
      return end
    }

    /// Where a tag that opens at `index` (`<`) ends, past its `>` on the
    /// line; nil where `<` opens none. A tag's name begins with a letter,
    /// as CommonMark's does, or with `|` or a non-ASCII character, as a
    /// chat template's tokens do (`<|im_start|>`, `<｜User｜>`), so `x < y`
    /// and `a<3` stay text.
    func markupTagEnd(_ index: Int, _ to: Int) -> Int? {
      var cursor = index + 1
      if cursor < to, text[cursor] == 0x2F { cursor += 1 }
      guard cursor < to else { return nil }
      let first = text[cursor]
      guard (first >= 0x41 && first <= 0x5A) || (first >= 0x61 && first <= 0x7A) || first == 0x7C || first >= 0x80
      else { return nil }
      while cursor < to {
        if text[cursor] == 0x3E { return cursor + 1 }
        if text[cursor] == 0x3C { return nil }
        cursor += 1
      }
      return nil
    }

    /// Closing emphasis runs found ahead on the line, colored when reached.
    var closers: [(at: Int, length: Int)] = []

    /// A line's inline text, `from` to `to`.
    func inline(_ from: Int, _ to: Int) -> Int {
      var index = from
      while index < to {
        let byte = text[index]
        if byte == 0x5C {
          // An escape: the next character is text.
          index += 2
        } else if byte == 0x60 {
          // Code: to a closing run of as many backticks on the line.
          let open = run(of: 0x60, from: index, to: to)
          let length = open - index
          var cursor = open
          var close = -1
          while cursor < to {
            if text[cursor] == 0x60 {
              let end = run(of: 0x60, from: cursor, to: to)
              if end - cursor == length {
                close = end
                break
              }
              cursor = end
            } else {
              cursor += 1
            }
          }
          if close >= 0 {
            add(.cdata, index, close)
            index = close
          } else {
            index = open
          }
        } else if byte == 0x3C, starts("<!--", at: index) {
          // A comment, across lines if it runs on: the read resumes past it.
          var end = index + 4
          while end < text.count, !starts("-->", at: end) { end += 1 }
          end = min(end + 3, text.count)
          add(.comment, index, end)
          return end
        } else if byte == 0x3C, starts("<http", at: index) {
          // An autolink: its URL inside the marks.
          var end = index + 1
          while end < to, text[end] != 0x3E, !isSpace(text[end]) { end += 1 }
          if end < to, text[end] == 0x3E { add(.prefix, index + 1, end) }
          index = end
        } else if byte == 0x3C, let close = markupTagEnd(index, to) {
          // A tag (CommonMark's raw HTML), and a chat template's tokens
          // with it: `<think>`, `<|im_start|>`, `<｜DSML｜ invoke name="…">`.
          // Read by XML's grammar, as a fence that names XML.
          let base = units.at(index, in: text)
          for token in XMLSyntax.tokens(Array(text[index..<close])) {
            out.append(Token(kind: token.kind, start: base + token.start, end: base + token.end))
          }
          index = close
        } else if byte == 0x5D, index + 1 < to, text[index + 1] == 0x28 {
          // A link's or image's destination: `](url)`, its URL indigo.
          var end = index + 2
          while end < to, text[end] != 0x29, !isSpace(text[end]) { end += 1 }
          add(.prefix, index + 2, end)
          index = end
        } else if byte == 0x2A || byte == 0x5F {
          let end = run(of: byte, from: index, to: to)
          if let found = closers.firstIndex(where: { $0.at == index && $0.length == end - index }) {
            add(.pi, index, end)
            closers.remove(at: found)
            index = end
            continue
          }
          // An opening run: before a word, and for `_` not inside one; its
          // closer as long, after a word, later on the line.
          let length = end - index
          let before: UInt8 = index > 0 ? text[index - 1] : 0x20
          let opens = end < to && !isSpace(text[end]) && (byte == 0x2A || !isWord(before))
          var close = -1
          if opens {
            var cursor = end + 1
            while cursor < to {
              if text[cursor] == byte {
                let closeEnd = run(of: byte, from: cursor, to: to)
                let after: UInt8 = closeEnd < to ? text[closeEnd] : 0x20
                if closeEnd - cursor == length, !isSpace(text[cursor - 1]), byte == 0x2A || !isWord(after) {
                  close = cursor
                  break
                }
                cursor = closeEnd
              } else {
                cursor += text[cursor] == 0x5C ? 2 : 1
              }
            }
          }
          if close >= 0 {
            add(.pi, index, end)
            closers.append((close, length))
          }
          index = end
        } else {
          index += 1
        }
      }
      return to
    }

    /// The fence open: its mark, its length, and the language it names.
    var fence: (mark: UInt8, length: Int, language: CodeSyntax.Language?, content: Int)? = nil

    var index = 0
    while index < text.count {
      let end = lineEnd(index)
      var cursor = index
      var indent = 0
      while cursor < end, text[cursor] == 0x20, indent < 3 {
        cursor += 1
        indent += 1
      }

      if let open = fence {
        // Inside a fence: its closing line ends it.
        let close = run(of: open.mark, from: cursor, to: end)
        var rest = close
        while rest < end, isSpace(text[rest]) { rest += 1 }
        if close - cursor >= open.length, rest == end {
          if let language = open.language {
            let base = units.at(open.content, in: text)
            for token in CodeSyntax.tokens(Array(text[open.content..<index]), language: language) {
              out.append(Token(kind: token.kind, start: base + token.start, end: base + token.end))
            }
          }
          add(.cdata, index, end)
          fence = nil
        } else if open.language == nil {
          add(.cdata, index, end)
        }
        index = end + 1
        continue
      }

      let byte = cursor < end ? text[cursor] : 0
      if byte == 0x60 || byte == 0x7E {
        let markEnd = run(of: byte, from: cursor, to: end)
        if markEnd - cursor >= 3 {
          // A fence opens: its info string names the language.
          var word = markEnd
          while word < end, isSpace(text[word]) { word += 1 }
          var wordEnd = word
          while wordEnd < end, !isSpace(text[wordEnd]), text[wordEnd] != 0x7B { wordEnd += 1 }
          var language: CodeSyntax.Language? = nil
          if spells(word, wordEnd, "xml") || spells(word, wordEnd, "tei") || spells(word, wordEnd, "html") {
            language = .xml
          } else if spells(word, wordEnd, "json") {
            language = .json
          }
          add(.cdata, index, end)
          fence = (byte, markEnd - cursor, language, min(end + 1, text.count))
          index = end + 1
          continue
        }
      }
      if byte == 0x23 {
        // A heading: `#`s, then a space or the line's end; the whole line.
        let marks = run(of: 0x23, from: cursor, to: end)
        if marks - cursor <= 6, marks == end || isSpace(text[marks]) {
          add(.name, cursor, end)
          index = end + 1
          continue
        }
      }
      if byte == 0x2D || byte == 0x2A || byte == 0x5F {
        // A rule: three or more of one mark, spaces between, nothing else.
        var count = 0
        var rest = cursor
        while rest < end, text[rest] == byte || isSpace(text[rest]) {
          if text[rest] == byte { count += 1 }
          rest += 1
        }
        if count >= 3, rest == end {
          add(.entity, cursor, end)
          index = end + 1
          continue
        }
      }
      // Quote marks, then a list's mark, at the line's start.
      while cursor < end, text[cursor] == 0x3E {
        add(.entity, cursor, cursor + 1)
        cursor += 1
        while cursor < end, isSpace(text[cursor]) { cursor += 1 }
      }
      while cursor < end, isSpace(text[cursor]) { cursor += 1 }
      if cursor < end {
        let mark = text[cursor]
        if (mark == 0x2D || mark == 0x2A || mark == 0x2B), cursor + 1 == end || isSpace(text[cursor + 1]) {
          add(.entity, cursor, cursor + 1)
          cursor += 1
        } else if mark >= 0x30 && mark <= 0x39 {
          var digits = cursor
          while digits < end, digits - cursor < 9, text[digits] >= 0x30 && text[digits] <= 0x39 { digits += 1 }
          if digits < end, text[digits] == 0x2E || text[digits] == 0x29,
            digits + 1 == end || isSpace(text[digits + 1])
          {
            add(.entity, cursor, digits + 1)
            cursor = digits + 1
          }
        }
      }
      closers.removeAll()
      // A comment that ran past its line resumes the read where it ended,
      // mid-line: that line's rest is text.
      var stop = end
      var resume = inline(cursor, end)
      while resume > stop {
        closers.removeAll()
        stop = lineEnd(resume)
        resume = inline(resume, stop)
      }
      index = stop + 1
    }
    if let open = fence, let language = open.language, open.content < text.count {
      // A fence left open runs to the text's end.
      let base = units.at(open.content, in: text)
      for token in CodeSyntax.tokens(Array(text[open.content..<text.count]), language: language) {
        out.append(Token(kind: token.kind, start: base + token.start, end: base + token.end))
      }
    }
    return out
  }
}
