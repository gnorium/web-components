#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Raw text, edited where it is read.
  ///
  /// A `CodeView` of the text whose text is itself editable (plain text
  /// only), colored as every code block on the site is. One layer: what is
  /// selected is the colored text, so a selection looks as the browser
  /// draws any, and a drag past the pane's edge scrolls it, as it does over
  /// any text. (A transparent textarea laid over the colors, as this was,
  /// held its own clipped scroller: a drag ran on under the edge with the
  /// pane, the selection drawn in a box left behind, and its selection had
  /// to be recolored by hand.)
  ///
  /// The text is colored by CSS highlights over its text node
  /// (`CodeEditorHydration`), not by markup written into it, so typing never
  /// loses the caret. A hidden textarea carries the value the form posts and
  /// its default; the client keeps it in step both ways.
  public struct CodeEditorView: HTMLContent {
    let id: String
    let name: String
    let value: String
    let language: String
    let ariaLabel: String
    /// Numbered, wide unless an ancestor reflows it (`CodeView.lined`).
    let lined: Bool

    public init(
      id: String, name: String, value: String, language: String = "xml", ariaLabel: String, lined: Bool = false
    ) {
      self.id = id
      self.name = name
      self.value = value
      self.language = language
      self.ariaLabel = ariaLabel
      self.lined = lined
    }

    public func build() -> DOM.Node {
      div {
        CodeView(value, language: language, showLineNumbers: false, editableLabel: ariaLabel, lined: lined)
        textarea(value)
          .id(id)
          .name(name)
          .hidden(true)
          .class("code-editor-input")
      }
      .class("code-editor-view")
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.column)
          minWidth(0)
        }
        // At a field's 16px (user, 2026-10-08): under 16px, iOS Safari zooms
        // the page as the text is focused. Its surface is the pane's.
        descendant(".code-view") {
          backgroundColor(.transparent)
          padding(0)
          borderRadius(0)
          overflow(.visible)
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightSmall22)
        }
        descendant(".code-code") {
          outline(.none)
          caretColor(colorBase)
          // Over the caret's line band, which stands behind it.
          position(.relative)
        }
        // The caret's line (user, 2026-10-12), as Xcode marks it: the neutral
        // subtle fill (the page's gray at `opacity-low`) across the whole width,
        // gutter to edge, every row it wraps to; its number in the text's own
        // color. Only while the editor has the focus and the selection is
        // within one line.
        descendant(".code-current-line") {
          display(.none)
          position(.absolute)
          insetInlineStart(px(0))
          insetInlineEnd(px(0))
          backgroundColor(backgroundColorCurrentLine)
          pointerEvents(.none)
        }
        descendant(".code-view[data-current-line='true'] .code-current-line") {
          display(.block)
        }
        descendant(".code-view[data-current-line='true'] .code-gutter-lines > span[data-current='true']") {
          color(colorBase)
        }
      }
      .build()
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Keeps each editor's text and its form's textarea in step, both ways,
  /// and colors the text by highlights (`CodeSyntax`) once it can be seen,
  /// again a moment after typing stops. Highlights paint over the text node
  /// and write nothing into it, so the caret and the selection stay as the
  /// person left them.
  public enum CodeEditorHydration {
    /// One editor: its text, its form's textarea, its language, and its
    /// colored stretches, by `CodeSyntax.Kind`.
    final class Editor: @unchecked Sendable {
      let code: DOM.Element
      /// The form's textarea; nil for text that is only read.
      let input: HTML.HTMLTextAreaElement?
      let language: CodeSyntax.Language
      /// Its stretches as last colored: the whole text's, read in one pass.
      var tokens: [CodeSyntax.Token] = []
      /// The ranges of the stretches painted now, by index: only those on
      /// and near the lines the pane shows (`paintWindow`). A long page's
      /// ten thousand stretches as live ranges cost every keystroke—the
      /// browser moves each live range with every edit (WebKit took
      /// seconds), and repaints every range of a highlight that changes
      /// (Chrome, a 50 ms frame; user, 2026-10-15).
      var live: [Int: DOM.Range] = [:]
      /// One character's width, measured once (the text is monospaced):
      /// which columns the pane shows.
      var charWidth = 0.0
      /// Its text nodes as last read, where a stretch's range is set.
      var nodes: [(node: DOM.Text, start: Int, end: Int)] = []
      /// Its text as last colored (UTF-8) and how many text nodes held it:
      /// an edit is found against them (`color`).
      var bytes: [UInt8] = []
      var nodeCount = 0
      var colored = false
      /// Whether it is on screen: painted only then.
      var shown = false
      /// Its lines' starts (UTF-16) and tops (from its view's top), as
      /// `number` last measured them; empty for text that is not lined.
      var lineStarts: [Int] = []
      var lineTops: [Double] = []
      var timer: Int32 = 0

      init(code: DOM.Element, input: HTML.HTMLTextAreaElement?) {
        self.code = code
        self.input = input
        self.language = CodeEditorHydration.language(of: code)
      }
    }

    /// The grammar a block is read by: its `data-code-syntax` (`xml`,
    /// `json`, `markdown`, `chat-template`), XML when it names none.
    static func language(of code: DOM.Element) -> CodeSyntax.Language {
      guard let name = code.dataset["codeSyntax"] else { return .xml }
      if stringEquals(name, "json") { return .json }
      if stringEquals(name, "markdown") { return .markdown }
      if stringEquals(name, "chat-template") { return .chatTemplate }
      return .xml
    }

    nonisolated(unsafe) static var editors: [Editor] = []
    /// One highlight a kind, registered under its name, holding every
    /// editor's stretches of that kind.
    nonisolated(unsafe) static var highlights: [Highlight] = []

    /// The editors under `root` that nothing is keeping in step yet.
    public static func hydrate(in root: DOM.Element) {
      for view in root.querySelectorAll(".code-editor-view") {
        if view.hasAttribute("data-code-editor-hydrated") { continue }
        view.setAttribute(data("code-editor-hydrated"), "true")
        guard let input = view.querySelector(".code-editor-input") as? HTML.HTMLTextAreaElement,
          let code = view.querySelector(".code-code")
        else { continue }
        let editor = Editor(code: code, input: input)
        editors.append(editor)
        _ = code.addEventListener(.keydown) { event in
          if KeyboardShortcuts.editorOwns(event.key) { event.stopPropagation() }
        }
        // The caret's line shows while the editor has the focus.
        _ = code.addEventListener("focus") { _ in
          code.setAttribute(data("focused"), "true")
          if code.hasAttribute("data-code-lined") { markCurrentLine(code) }
        }
        _ = code.addEventListener("blur") { _ in
          code.removeAttribute(data("focused"))
          if code.hasAttribute("data-code-lined") { markCurrentLine(code) }
        }
        _ = code.addEventListener(.input) { _ in
          let text = code.textContent
          input.value = text
          // A line added or removed is numbered in the same frame (user,
          // 2026-10-15): the gutter never trails the text. A wrap changed
          // by typing within a line waits for the pause, as coloring does.
          if code.hasAttribute("data-code-lined"), lineCount(text) != numberedLines(code) { number(code) }
          // Colored in the same frame, only what the edit touched (`color`).
          color(editor)
          // Its listeners hear the edit as the textarea's own.
          input.dispatchEvent(.input)
          schedule(editor)
        }
        // A value set from elsewhere—a script, a test—is shown.
        _ = input.addEventListener(.input) { _ in
          let text = input.value
          guard !stringEquals(text, code.textContent) else { return }
          if code.hasAttribute("data-code-lined") {
            // Set from elsewhere, not typed: laid out as served.
            reline(code, text: text)
          } else {
            code.textContent = text
          }
          if code.hasAttribute("data-code-lined") { number(code) }
          color(editor)
        }
        colorIfVisible(code)
      }
      // The caret moved (a click, a key, typing, a script): its line marked
      // in the editor that has it.
      if !listensToSelection {
        listensToSelection = true
        _ = document.addEventListener("selectionchange") { _ in
          for code in document.querySelectorAll(".code-code[data-code-editing='true'][data-code-lined='true'][data-focused='true']") {
            markCurrentLine(code)
          }
        }
      }
      // A pane scrolled: the stretches it now shows painted, once a frame.
      if !listensToScroll {
        listensToScroll = true
        _ = document.addEventListener(
          "scroll",
          { _ in
            guard !scrollPending else { return }
            scrollPending = true
            _ = window.requestAnimationFrame {
              scrollPending = false
              for editor in editors where editor.shown { repaint(editor) }
            }
          }, capture: true, passive: true)
      }
      // A pane resized wraps lines anew: every shown editor renumbered.
      if !listensToResize {
        listensToResize = true
        _ = window.addEventListener(.resize) { _ in
          for code in document.querySelectorAll(".code-code[data-code-editing='true'][data-code-lined='true']") {
            number(code)
          }
        }
      }
    }

    /// Colors text that is only read (lined code, an XML block, a
    /// Markdown or JSON Raw) once, when it has a box on screen; a live
    /// stream's (`data-live-output`) again each time, since it grows.
    public static func colorTextIfVisible(_ code: DOM.Element) {
      let live = code.hasAttribute("data-live-output")
      guard live || !code.hasAttribute("data-code-colored"), let rect = code.getBoundingClientRect(),
        rect.height > 0
      else { return }
      if let viewer = editors.first(where: { $0.code.id == code.id }) {
        color(viewer)
        return
      }
      code.setAttribute(data("code-colored"), "true")
      let viewer = Editor(code: code, input: nil)
      editors.append(viewer)
      color(viewer)
    }

    /// Lined text laid out again as `text`'s lines (`CodeView.lines`), the
    /// caret kept where it stood in the text.
    static func reline(_ code: DOM.Element, text: String) {
      var caret = -1
      if let selection = window.getSelection(), selection.rangeCount > 0, let focus = selection.focusNode,
        code.contains(focus)
      {
        let before = document.createRange()
        before.setStart(code, 0)
        before.setEnd(focus, selection.focusOffset)
        caret = before.toString().utf16.count
      }
      let all = CodeLines.lines(of: text)
      var spans: [DOM.Element] = []
      for (index, line) in all.enumerated() {
        let span = document.createElement(.span)
        span.className = "code-line"
        span.setAttribute(.style, "--indent: " + intToString(line.indent))
        span.textContent = line.text + (index < all.count - 1 ? "\n" : "")
        spans.append(span)
      }
      code.replaceChildren(spans)
      code.setAttribute(.style, "--gutter: " + CodeLines.gutter(lines: all.count))
      guard caret >= 0, let selection = window.getSelection() else { return }
      var start = 0
      let walker = document.createTreeWalker(code, DOM.NodeFilter.SHOW_TEXT)
      while let next = walker.nextNode() {
        guard let node = next as? DOM.Text else { continue }
        let length = node.data.utf16.count
        if caret <= start + length {
          selection.collapse(node, caret - start)
          return
        }
        start += length
      }
    }

    /// How many lines `text` starts, as `number` counts them: a line
    /// begins at each character that opens the text or follows a line feed.
    static func lineCount(_ text: String) -> Int {
      var count = 0
      var atStart = true
      for byte in text.utf8 where byte & 0xC0 != 0x80 {
        if atStart { count += 1 }
        atStart = byte == 0x0A
      }
      // An empty text shows its first line's number.
      return max(count, 1)
    }

    /// How many numbers the editor's gutter shows now.
    static func numberedLines(_ code: DOM.Element) -> Int {
      code.parentElement?.querySelector(".code-gutter-lines")?.childElementCount ?? 0
    }

    /// A lined editor's numbers, beside its text and never in it: each
    /// logical line's top measured where the text now lays it out (a line
    /// the browser broke within a block is a line of its own), as
    /// CodeMirror and Monaco draw theirs. The editable text is never
    /// touched, so its undo is the browser's, whole.
    static func number(_ code: DOM.Element) {
      guard let gutter = code.parentElement?.querySelector(".code-gutter-lines"),
        let codeRect = code.getBoundingClientRect(), codeRect.height > 0,
        let parentRect = code.parentElement?.getBoundingClientRect()
      else { return }
      var starts: [(DOM.Text, Int)] = []
      var offsets: [Int] = []
      var atStart = true
      var total = 0
      let walker = document.createTreeWalker(code, DOM.NodeFilter.SHOW_TEXT)
      while let next = walker.nextNode() {
        guard let node = next as? DOM.Text else { continue }
        var index = 0
        for unit in node.data.utf16 {
          if atStart {
            starts.append((node, index))
            offsets.append(total)
          }
          atStart = unit == 0x0A
          index += 1
          total += 1
        }
      }
      var tops: [Double] = []
      var numbers: [DOM.Element] = []
      // An empty editor still has its first line (user, 2026-10-15).
      if starts.isEmpty {
        let number = document.createElement(.span)
        number.textContent = "1"
        number.setAttribute(.style, "top: " + intToString(Int(codeRect.top - parentRect.top)) + "px")
        number.setAttribute(data("top"), doubleToString(codeRect.top - parentRect.top))
        numbers.append(number)
      }
      for (line, start) in starts.enumerated() {
        let range = document.createRange()
        range.setStart(start.0, start.1)
        range.setEnd(start.0, start.1 + 1)
        guard let rect = range.getBoundingClientRect() else { continue }
        tops.append(rect.top - parentRect.top)
        let number = document.createElement(.span)
        number.textContent = intToString(line + 1)
        number.setAttribute(.style, "top: " + intToString(Int(rect.top - parentRect.top)) + "px")
        number.setAttribute(data("top"), doubleToString(rect.top - parentRect.top))
        numbers.append(number)
      }
      // The column as wide as the widest number, never narrower than one
      // digit; the code is set off by it (its own `--gutter`), so a line
      // the browser wrote outside a line's block—typed into an emptied
      // editor, pasted—is never under the numbers (user, 2026-10-15).
      let width = CodeLines.gutter(lines: max(starts.count, 1))
      code.style.setProperty("--gutter", width)
      gutter.setAttribute(
        .style, "left: " + intToString(Int(codeRect.left - parentRect.left)) + "px; --gutter: " + width)
      gutter.replaceChildren(numbers)
      markCurrentLine(code)
      // Where its lines stand, for the stretches painted (`paintWindow`).
      if let editor = editors.first(where: { $0.code.id == code.id }) {
        editor.lineStarts = tops.count == offsets.count ? offsets : []
        editor.lineTops = tops.count == offsets.count ? tops : []
        repaint(editor)
      }
    }

    nonisolated(unsafe) static var listensToSelection = false

    /// The caret's logical line marked (`.code-current-line`, its gutter
    /// number `data-current`): from the line's first character to the
    /// next line's (or the text's end), every row it wraps to; hidden
    /// unless the editor has the focus and the selection is within one
    /// line. Read from the selection, as the caret moves however it moves.
    static func markCurrentLine(_ code: DOM.Element) {
      guard let view = code.parentElement, let gutter = view.querySelector(".code-gutter-lines") else { return }
      func hide() {
        if view.hasAttribute(data("current-line")) { view.removeAttribute(data("current-line")) }
      }
      guard stringEquals(code.getAttribute(data("focused")) ?? "", "true"), let selection = window.getSelection(),
        selection.rangeCount > 0, let focus = selection.focusNode, let anchor = selection.anchorNode,
        code.contains(focus), code.contains(anchor)
      else { return hide() }
      /// The logical line a point of the text is on: the line breaks before it.
      func line(_ node: DOM.Node, _ offset: Int) -> Int {
        let before = document.createRange()
        before.setStart(code, 0)
        before.setEnd(node, offset)
        var breaks = 0
        for byte in before.toString().utf8 where byte == 0x0A { breaks += 1 }
        return breaks
      }
      let current = line(focus, selection.focusOffset)
      guard selection.isCollapsed || line(anchor, selection.anchorOffset) == current else { return hide() }
      let numbers = gutter.querySelectorAll(":scope > span")
      guard current < numbers.count, let codeRect = code.getBoundingClientRect(),
        let viewRect = view.getBoundingClientRect()
      else { return hide() }
      let top = parseDouble(numbers[current].getAttribute(data("top")) ?? "") ?? 0
      let bottom =
        current + 1 < numbers.count
        ? parseDouble(numbers[current + 1].getAttribute(data("top")) ?? "") ?? top
        : codeRect.bottom - viewRect.top
      var band = view.querySelector(":scope > .code-current-line")
      if band == nil, let first = view.firstChild {
        let made = document.createElement(.div)
        made.className = "code-current-line"
        made.setAttribute("aria-hidden", "true")
        view.insertBefore(made, first)
        band = made
      }
      band?.setAttribute(.style, "top: " + doubleToString(top) + "px; height: " + doubleToString(bottom - top) + "px")
      for (index, number) in numbers.enumerated() {
        if index == current {
          number.setAttribute(data("current"), "true")
        } else if number.hasAttribute(data("current")) {
          number.removeAttribute(data("current"))
        }
      }
      view.setAttribute(data("current-line"), "true")
    }

    /// Colors an editor's text the first time it has a box on screen.
    public static func colorIfVisible(_ code: DOM.Element) {
      guard let rect = code.getBoundingClientRect(), rect.height > 0 else { return }
      // Its numbers as it is laid out now: shown, or the pane resized.
      if code.hasAttribute("data-code-lined") { number(code) }
      guard let editor = editors.first(where: { $0.code.id == code.id }), !editor.colored else { return }
      color(editor)
    }

    nonisolated(unsafe) static var listensToResize = false
    nonisolated(unsafe) static var listensToScroll = false
    nonisolated(unsafe) static var scrollPending = false

    /// Lined text typed into: its numbers measured again beside it once
    /// typing pauses, for a line the typing wrapped anew. A line added or
    /// removed is numbered at once (the input's own listener).
    private static func schedule(_ editor: Editor) {
      guard editor.code.hasAttribute("data-code-lined") else { return }
      if editor.timer != 0 { window.clearTimeout(editor.timer) }
      editor.timer = window.setTimeout(150) {
        editor.timer = 0
        number(editor.code)
      }
    }

    /// The editor's stretches found again over its text nodes as they now
    /// stand. The whole text is read again—a comment or CDATA opened or
    /// closed recolors all it reaches—but only the stretches on and near
    /// the lines on screen have ranges and are painted, and of those only
    /// the ones an edit touched are set anew: those before it keep their
    /// ranges, and those after it too, which the browser moved with the
    /// text as it was typed into. An edit across text nodes (a paste over
    /// lines, a selection deleted), or a range the browser did not carry,
    /// sets the painted ones anew.
    static func color(_ editor: Editor) {
      var nodes: [(node: DOM.Text, start: Int, end: Int)] = []
      var bytes: [UInt8] = []
      var units = 0
      let walker = document.createTreeWalker(editor.code, DOM.NodeFilter.SHOW_TEXT)
      while let next = walker.nextNode() {
        guard let node = next as? DOM.Text else { continue }
        let text = node.data
        var length = 0
        for byte in text.utf8 where byte & 0xC0 != 0x80 { length += byte >= 0xF0 ? 2 : 1 }
        bytes.append(contentsOf: text.utf8)
        nodes.append((node, units, units + length))
        units += length
      }
      let tokens = CodeSyntax.tokens(bytes, language: editor.language)
      editor.nodes = nodes

      var carried = false
      if editor.colored, nodes.count == editor.nodeCount, let edit = edited(old: editor.bytes, new: bytes) {
        let start = unitCount(in: bytes, upTo: edit.prefix)
        let oldEnd = unitCount(in: editor.bytes, upTo: editor.bytes.count - edit.suffix)
        let newEnd = unitCount(in: bytes, upTo: bytes.count - edit.suffix)
        let delta = newEnd - oldEnd
        // Within one text node, before and after.
        if let first = place(start, opening: true, in: nodes), let last = place(newEnd, opening: false, in: nodes),
          first.0.id == last.0.id
        {
          let old = editor.tokens
          var head = 0
          while head < old.count, head < tokens.count, old[head] == tokens[head], old[head].end <= start { head += 1 }
          var oldTail = old.count
          var newTail = tokens.count
          while oldTail > head, newTail > head {
            let a = old[oldTail - 1]
            let b = tokens[newTail - 1]
            guard a.start >= oldEnd, a.kind == b.kind, a.start + delta == b.start, a.end + delta == b.end else { break }
            oldTail -= 1
            newTail -= 1
          }
          let shift = (newTail - head) - (oldTail - head)
          // The painted ranges carried: those before the edit as they are,
          // those after it under their new places, the edit's own out.
          var live: [Int: DOM.Range] = [:]
          var gone: [(CodeSyntax.Token, DOM.Range)] = []
          var check: (index: Int, range: DOM.Range)?
          for (index, range) in editor.live {
            if index < head {
              live[index] = range
            } else if index >= oldTail {
              live[index + shift] = range
              if check == nil || index + shift < check!.index { check = (index + shift, range) }
            } else {
              gone.append((old[index], range))
            }
          }
          // The first range kept after the edit still covers its token.
          var sound = true
          if let check, check.index < tokens.count {
            let token = tokens[check.index]
            sound = Array(check.range.toString().utf16).count == token.end - token.start
          }
          if sound {
            if editor.shown { paint(removing: gone, adding: []) }
            editor.tokens = tokens
            editor.live = live
            carried = true
          }
        }
      }
      if !carried {
        // Every painted range set anew.
        if editor.shown {
          var gone: [(CodeSyntax.Token, DOM.Range)] = []
          for (index, range) in editor.live where index < editor.tokens.count { gone.append((editor.tokens[index], range)) }
          paint(removing: gone, adding: [])
        }
        editor.tokens = tokens
        editor.live = [:]
      }
      editor.bytes = bytes
      editor.nodeCount = nodes.count
      editor.colored = true
      // Colored because it is on screen: painted.
      editor.shown = true
      repaint(editor)
    }

    /// The node a point stands in, and its place there: a point at a
    /// node's end is in it (a stretch's end), unless it opens the next.
    static func place(_ offset: Int, opening: Bool, in nodes: [(node: DOM.Text, start: Int, end: Int)]) -> (DOM.Text, Int)? {
      var low = 0
      var high = nodes.count
      while low < high {
        let middle = (low + high) / 2
        if opening ? offset >= nodes[middle].end : offset > nodes[middle].end { low = middle + 1 } else { high = middle }
      }
      guard low < nodes.count else { return nil }
      return (nodes[low].node, offset - nodes[low].start)
    }

    /// The stretches of an editor on screen painted for the lines the pane
    /// shows and a little either side (`paintWindow`), each given its range
    /// as it comes into view; the rest taken out, their ranges let go.
    static func repaint(_ editor: Editor) {
      // Text whose lines were never measured is painted whole, once: a
      // scroll over it changes nothing, and walking its every stretch each
      // frame (a session's Raw holds tens of thousands) stalled the scroll.
      if editor.shown, editor.lineTops.isEmpty, editor.live.count == editor.tokens.count { return }
      let want = editor.shown ? paintWindow(editor) : []
      var wanted = Set<Int>()
      for index in want { wanted.insert(index) }
      var removing: [(CodeSyntax.Token, DOM.Range)] = []
      var adding: [(CodeSyntax.Token, DOM.Range)] = []
      for (index, range) in editor.live where !wanted.contains(index) {
        if index < editor.tokens.count { removing.append((editor.tokens[index], range)) }
        editor.live[index] = nil
      }
      for index in want where editor.live[index] == nil {
        let token = editor.tokens[index]
        guard let start = place(token.start, opening: true, in: editor.nodes),
          let end = place(token.end, opening: false, in: editor.nodes)
        else { continue }
        let range = document.createRange()
        range.setStart(start.0, start.1)
        range.setEnd(end.0, end.1)
        editor.live[index] = range
        adding.append((token, range))
      }
      paint(removing: removing, adding: adding)
    }

    /// The stretches the pane shows, and a little round them: on the lines
    /// it shows, and of those lines the columns it shows (user,
    /// 2026-10-15)—a page's lines run far past the pane's edge. All of them
    /// for text whose lines were never measured; every column where lines
    /// wrap (Reflow).
    static func paintWindow(_ editor: Editor) -> [Int] {
      let all = Array(0..<editor.tokens.count)
      guard !editor.lineTops.isEmpty, editor.lineTops.count == editor.lineStarts.count,
        let view = editor.code.parentElement, let viewRect = view.getBoundingClientRect()
      else { return all }
      let scroller = editor.code.closest(".artifact-markup")
      let pane = scroller?.getBoundingClientRect()
      let height = window.innerHeight
      let top = max(pane?.top ?? 0, 0) - viewRect.top
      let bottom = min(pane?.bottom ?? height, height) - viewRect.top
      // A little either side, so a scroll shows color before it is
      // repainted the next frame.
      let reach = 120.0
      var first = 0
      while first + 1 < editor.lineTops.count, editor.lineTops[first + 1] < top - reach { first += 1 }
      var last = first
      while last + 1 < editor.lineTops.count, editor.lineTops[last + 1] <= bottom + reach { last += 1 }
      let from = editor.lineStarts[first]
      let to = last + 1 < editor.lineStarts.count ? editor.lineStarts[last + 1] : Int.max
      // The first stretch ending after `from`, and the first starting at or after `to`.
      var low = 0
      var high = editor.tokens.count
      while low < high {
        let middle = (low + high) / 2
        if editor.tokens[middle].end <= from { low = middle + 1 } else { high = middle }
      }
      let start = low
      high = editor.tokens.count
      while low < high {
        let middle = (low + high) / 2
        if editor.tokens[middle].start < to { low = middle + 1 } else { high = middle }
      }
      let lines = start..<max(start, low)
      // The columns the pane shows, where lines do not wrap.
      let wraps = editor.code.closest("[data-reflow='true']") != nil
      guard !wraps, let codeRect = editor.code.getBoundingClientRect(), let width = charWidth(editor), width > 0
      else { return Array(lines) }
      let gutter = parseDouble(stringRemoveSuffix(window.getComputedStyle(editor.code).getPropertyValue("padding-inline-start"), "px")) ?? 0
      let textLeft = codeRect.left + gutter
      let left = max(pane?.left ?? 0, 0)
      let right = min(pane?.right ?? window.innerWidth, window.innerWidth)
      let margin = 20
      let firstColumn = Int((left - textLeft) / width) - margin
      let lastColumn = Int((right - textLeft) / width) + 1 + margin
      var shown: [Int] = []
      var line = first
      for index in lines {
        let token = editor.tokens[index]
        while line + 1 < editor.lineStarts.count, editor.lineStarts[line + 1] <= token.start { line += 1 }
        let column = token.start - editor.lineStarts[line]
        let length = token.end - token.start
        if column + length >= firstColumn && column <= lastColumn { shown.append(index) }
      }
      return shown
    }

    /// One character's width in the editor's text, measured once.
    static func charWidth(_ editor: Editor) -> Double? {
      if editor.charWidth > 0 { return editor.charWidth }
      for (node, _, _) in editor.nodes {
        var offset = 0
        for unit in node.data.utf16 {
          if unit != 0x0A && unit != 0x09 && unit != 0x20 {
            let range = document.createRange()
            range.setStart(node, offset)
            range.setEnd(node, offset + 1)
            guard let rect = range.getBoundingClientRect(), rect.width > 0 else { return nil }
            editor.charWidth = rect.width
            return rect.width
          }
          offset += 1
          if offset > 64 { break }
        }
      }
      return nil
    }

    /// Each colored editor painted while it has a box on screen, for the
    /// lines its pane shows, and taken out of the highlights while it has
    /// none (a page turned away, Raw put away).
    public static func paintVisible() {
      for editor in editors where editor.colored {
        editor.shown = (editor.code.getBoundingClientRect()?.height ?? 0) > 0
        repaint(editor)
      }
    }

    /// Where two texts differ: how many bytes they share at the start and,
    /// apart from those, at the end. Nil when they are the same.
    static func edited(old: [UInt8], new: [UInt8]) -> (prefix: Int, suffix: Int)? {
      guard old != new else { return nil }
      let shortest = min(old.count, new.count)
      var prefix = 0
      while prefix < shortest, old[prefix] == new[prefix] { prefix += 1 }
      // Never inside a character: back to its first byte.
      while prefix > 0, prefix < new.count, new[prefix] & 0xC0 == 0x80 { prefix -= 1 }
      var suffix = 0
      while suffix < shortest - prefix, old[old.count - 1 - suffix] == new[new.count - 1 - suffix] { suffix += 1 }
      while suffix > 0, new.count - suffix < new.count, new[new.count - suffix] & 0xC0 == 0x80 { suffix -= 1 }
      return (prefix, suffix)
    }

    /// The UTF-16 units of `bytes`' first `count` bytes.
    static func unitCount(in bytes: [UInt8], upTo count: Int) -> Int {
      var units = 0
      for byte in bytes[0..<count] where byte & 0xC0 != 0x80 { units += byte >= 0xF0 ? 2 : 1 }
      return units
    }

    /// Stretches out of their kinds' highlights and stretches into them;
    /// every other block's stay as they are.
    private static func paint(
      removing old: [(CodeSyntax.Token, DOM.Range)], adding new: [(CodeSyntax.Token, DOM.Range)]
    ) {
      if highlights.isEmpty {
        for kind in CodeSyntax.Kind.allCases {
          let highlight = Highlight()
          CSS.highlights.set(kind.highlightName, highlight)
          highlights.append(highlight)
        }
      }
      for (token, range) in old { highlights[token.kind.rawValue].delete(range) }
      for (token, range) in new { highlights[token.kind.rawValue].add(range) }
    }
  }
#endif
