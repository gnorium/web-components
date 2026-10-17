/// A chat template's rendered text, as a session's Raw shows it
/// (`data-code-syntax="chat-template"`): Markdown (`MarkdownSyntax`), its
/// tokens read as tags, and JSON (`JSONSyntax`) where the template puts JSON,
/// found by the wrapper the template writes around it, never by a guess at
/// what looks like JSON. Markdown elsewhere is read as before.
///
/// The wrappers, from the pinned templates (gnorium-python
/// `chat_templates/`):
///
/// - `deepseek-v4.1/chat_template.jinja`, line 204: a tool's result is
///   written `"<tool_result>" ~ tc ~ "</tool_result>"`, its content as the
///   tool returned it; JSON where the tool's result is.
/// - the same, line 227: a call's argument is written
///   `<｜DSML｜ parameter name="…" string="…">…</｜DSML｜ parameter>`, the
///   value as is where it is a string (`string="true"`), and `v | tojson`
///   where it is not (`string="false"`); line 69 tells the model the same.
/// - the same, lines 69–71 (`render_tools`): the tool schemas are written
///   after `"### Available Tool Schemas\n\n"` (line 69) as
///   `ts.schemas | join("\n")` (line 70), each schema `tojson` (line 67),
///   so one a line, and before `"\n\nYou MUST strictly follow the above
///   defined tool name and parameter schemas to invoke tool calls.\n"`
///   (line 71).
///
/// Each is colored as JSON only where its content is one JSON value
/// (`JSONSyntax.accepts`)—a schema line by line—; a result that is text
/// stays Markdown, and a `string="true"` value is never read as JSON.
public enum ChatTemplateSyntax {
  public typealias Token = CodeSyntax.Token

  public static func tokens(_ text: [UInt8]) -> [Token] {
    var clean = 0
    return tokens(text, clean: &clean)
  }

  /// The same, and `clean`: the last line start where a read may begin
  /// afresh (`CodeSyntax.tokens(_:language:clean:)`)—Markdown's state the
  /// starting one there (`MarkdownSyntax`), no wrapper open across it, and
  /// none before it left unclosed (whose content the text to come decides).
  public static func tokens(_ text: [UInt8], clean: inout Int) -> [Token] {
    let found = scan(text)
    let regions = found.regions
    var points: [Int] = []
    defer { clean = lastClean(text, points, regions: regions, spans: found.spans, unclosed: found.unclosed) }
    guard !regions.isEmpty else { return MarkdownSyntax.tokens(text, clean: &points) }

    // Markdown reads the text with each JSON region blanked: a space for
    // each UTF-16 unit, line feeds kept, so its stretches fall where the
    // text's do and nothing in the JSON (a `<!--`, a fence's backticks)
    // reads as Markdown.
    var masked: [UInt8] = []
    masked.reserveCapacity(text.count)
    var next = 0
    for region in regions {
      masked.append(contentsOf: text[next..<region.from])
      var index = region.from
      while index < region.to {
        let byte = text[index]
        if byte == 0x0A {
          masked.append(0x0A)
        } else if byte & 0xC0 != 0x80 {
          masked.append(0x20)
          if byte >= 0xF0 { masked.append(0x20) }
        }
        index += 1
      }
      next = region.to
    }
    masked.append(contentsOf: text[next..<text.count])

    var out = MarkdownSyntax.tokens(masked, clean: &points)
    var units = CodeSyntax.Units()
    for region in regions {
      let base = units.at(region.from, in: text)
      for token in JSONSyntax.tokens(Array(text[region.from..<region.to])) {
        out.append(Token(kind: token.kind, start: base + token.start, end: base + token.end))
      }
    }
    out.sort { $0.start < $1.start }
    return out
  }

  /// Of Markdown's clean points (`points`, read in the masked text, where
  /// each region's every UTF-16 unit is a space), the last in the text's
  /// bytes that no wrapper spans and no unclosed wrapper precedes; 0 for
  /// none.
  static func lastClean(
    _ text: [UInt8], _ points: [Int], regions: [(from: Int, to: Int)], spans: [(from: Int, to: Int)],
    unclosed: Int
  ) -> Int {
    // Each region's place in the masked text, and the bytes the text holds
    // more than the masked text by its end.
    var places: [(from: Int, to: Int, shift: Int)] = []
    var shift = 0
    for region in regions {
      var length = 0
      var index = region.from
      while index < region.to {
        let byte = text[index]
        if byte == 0x0A || byte & 0xC0 != 0x80 { length += byte >= 0xF0 ? 2 : 1 }
        index += 1
      }
      let from = region.from - shift
      shift += (region.to - region.from) - length
      places.append((from, from + length, shift))
    }
    var place = places.count
    var span = spans.count
    var index = points.count
    while index > 0 {
      index -= 1
      let point = points[index]
      // The last region before or around it.
      while place > 0, places[place - 1].from >= point { place -= 1 }
      var offset = point
      if place > 0 {
        let region = places[place - 1]
        if point < region.to { continue }
        offset = point + region.shift
      }
      guard offset <= unclosed else { continue }
      while span > 0, spans[span - 1].from >= offset { span -= 1 }
      if span > 0, offset < spans[span - 1].to { continue }
      return offset
    }
    return 0
  }

  /// The JSON the pinned templates write, by their wrappers: each region's
  /// bytes, in order.
  static func jsonRegions(_ text: [UInt8]) -> [(from: Int, to: Int)] {
    scan(text).regions
  }

  /// The wrappers the pinned templates write: the JSON regions in them
  /// (`jsonRegions`), every wrapper's whole span, opener to closer, JSON or
  /// not, and where one opens that the text has not closed (its length
  /// when none does).
  static func scan(_ text: [UInt8]) -> (regions: [(from: Int, to: Int)], spans: [(from: Int, to: Int)], unclosed: Int) {
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
    /// Where `marker` next begins, from `index`; nil where it never does.
    func find(_ marker: StaticString, from index: Int) -> Int? {
      let first = marker.utf8Start[0]
      var cursor = index
      while cursor < text.count {
        if text[cursor] == first, starts(marker, at: cursor) { return cursor }
        cursor += 1
      }
      return nil
    }

    let resultOpen: StaticString = "<tool_result>"
    let resultClose: StaticString = "</tool_result>"
    let parameterOpen: StaticString = "<｜DSML｜ parameter "
    let parameterClose: StaticString = "</｜DSML｜ parameter>"
    let schemasOpen: StaticString = "### Available Tool Schemas\n\n"
    let schemasClose: StaticString =
      "\n\nYou MUST strictly follow the above defined tool name and parameter schemas to invoke tool calls.\n"

    var regions: [(from: Int, to: Int)] = []
    var spans: [(from: Int, to: Int)] = []
    var unclosed = text.count
    // An opener the text ends partway through is one it has not closed.
    for opener in [resultOpen, parameterOpen, schemasOpen] {
      var length = min(opener.utf8CodeUnitCount - 1, text.count)
      while length > 0 {
        var matches = true
        var offset = 0
        while offset < length {
          if text[text.count - length + offset] != opener.utf8Start[offset] {
            matches = false
            break
          }
          offset += 1
        }
        if matches {
          unclosed = min(unclosed, text.count - length)
          break
        }
        length -= 1
      }
    }
    var index = 0
    while index < text.count {
      if text[index] == 0x23, starts(schemasOpen, at: index) {
        // deepseek-v4.1, lines 69–71: one schema a line, each line JSON
        // where it is one value. Read whole, so nothing in a schema's
        // description reads as a wrapper.
        let from = index + schemasOpen.utf8CodeUnitCount
        guard let close = find(schemasClose, from: from) else {
          unclosed = min(unclosed, index)
          break
        }
        spans.append((index, close + schemasClose.utf8CodeUnitCount))
        var line = from
        while line < close {
          var end = line
          while end < close, text[end] != 0x0A { end += 1 }
          if JSONSyntax.accepts(text, from: line, to: end) { regions.append((line, end)) }
          line = end + 1
        }
        index = close + schemasClose.utf8CodeUnitCount
        continue
      }
      guard text[index] == 0x3C else {
        index += 1
        continue
      }
      if starts(resultOpen, at: index) {
        // deepseek-v4.1, line 204.
        let from = index + resultOpen.utf8CodeUnitCount
        guard let close = find(resultClose, from: from) else {
          unclosed = min(unclosed, index)
          break
        }
        spans.append((index, close + resultClose.utf8CodeUnitCount))
        if JSONSyntax.accepts(text, from: from, to: close) { regions.append((from, close)) }
        index = close + resultClose.utf8CodeUnitCount
      } else if starts(parameterOpen, at: index) {
        // deepseek-v4.1, line 227: the tag to its `>`, quoted values
        // skipped, on its line.
        var cursor = index + parameterOpen.utf8CodeUnitCount
        var quoted = false
        var json = false
        while cursor < text.count, text[cursor] != 0x0A, quoted || text[cursor] != 0x3E {
          if text[cursor] == 0x22 {
            quoted.toggle()
          } else if !quoted, starts(" string=\"false\"", at: cursor - 1) {
            json = true
          }
          cursor += 1
        }
        guard cursor < text.count, text[cursor] == 0x3E else {
          // A tag the text ends in may yet close.
          if cursor >= text.count { unclosed = min(unclosed, index) }
          index = cursor
          continue
        }
        let from = cursor + 1
        guard let close = find(parameterClose, from: from) else {
          unclosed = min(unclosed, index)
          break
        }
        spans.append((index, close + parameterClose.utf8CodeUnitCount))
        if json, JSONSyntax.accepts(text, from: from, to: close) { regions.append((from, close)) }
        index = close + parameterClose.utf8CodeUnitCount
      } else {
        index += 1
      }
    }
    return (regions, spans, unclosed)
  }
}
