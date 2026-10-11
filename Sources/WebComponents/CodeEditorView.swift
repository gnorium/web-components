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
    /// Numbered and soft-wrapped as Xcode's (`CodeView.lined`).
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
  /// and colors the text by highlights (`XMLSyntax`) once it can be seen,
  /// again a moment after typing stops. Highlights paint over the text node
  /// and write nothing into it, so the caret and the selection stay as the
  /// person left them.
  public enum CodeEditorHydration {
    /// One editor: its text, its form's textarea, and its colored
    /// stretches, by `XMLSyntax.Kind`.
    final class Editor: @unchecked Sendable {
      let code: DOM.Element
      /// The form's textarea; nil for lined text that is only read.
      let input: HTML.HTMLTextAreaElement?
      var ranges: [[DOM.Range]] = []
      var colored = false
      var timer: Int32 = 0

      init(code: DOM.Element, input: HTML.HTMLTextAreaElement?) {
        self.code = code
        self.input = input
      }
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
        _ = code.addEventListener(.input) { _ in
          input.value = code.textContent
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
          schedule(editor)
        }
        colorIfVisible(code)
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

    /// Colors lined text that is only read, once, when it has a box on
    /// screen.
    public static func colorLinedIfVisible(_ code: DOM.Element) {
      guard !code.hasAttribute("data-code-colored"), let rect = code.getBoundingClientRect(), rect.height > 0
      else { return }
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
      var atStart = true
      let walker = document.createTreeWalker(code, DOM.NodeFilter.SHOW_TEXT)
      while let next = walker.nextNode() {
        guard let node = next as? DOM.Text else { continue }
        var index = 0
        for unit in node.data.utf16 {
          if atStart { starts.append((node, index)) }
          atStart = unit == 0x0A
          index += 1
        }
      }
      var numbers: [DOM.Element] = []
      for (line, start) in starts.enumerated() {
        let range = document.createRange()
        range.setStart(start.0, start.1)
        range.setEnd(start.0, start.1 + 1)
        guard let rect = range.getBoundingClientRect() else { continue }
        let number = document.createElement(.span)
        number.textContent = intToString(line + 1)
        number.setAttribute(.style, "top: " + intToString(Int(rect.top - parentRect.top)) + "px; width: var(--gutter)")
        numbers.append(number)
      }
      gutter.setAttribute(
        .style,
        "left: " + intToString(Int(codeRect.left - parentRect.left)) + "px; --gutter: "
          + CodeLines.gutter(lines: starts.count))
      gutter.replaceChildren(numbers)
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

    private static func schedule(_ editor: Editor) {
      if editor.timer != 0 { window.clearTimeout(editor.timer) }
      editor.timer = window.setTimeout(150) {
        editor.timer = 0
        // Lined text typed into: its numbers measured again beside it.
        if editor.code.hasAttribute("data-code-lined") { number(editor.code) }
        color(editor)
      }
    }

    /// The editor's stretches found again over its text nodes as they now
    /// stand, and every highlight painted again.
    private static func color(_ editor: Editor) {
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
      var ranges = [[DOM.Range]](repeating: [], count: XMLSyntax.Kind.allCases.count)
      var current = 0
      /// The node a point stands in, and its place there: a point at a
      /// node's end is in it (a stretch's end), unless it opens the next.
      func place(_ offset: Int, opening: Bool) -> (DOM.Text, Int)? {
        while current < nodes.count,
          opening ? offset >= nodes[current].end : offset > nodes[current].end
        {
          current += 1
        }
        guard current < nodes.count else { return nil }
        return (nodes[current].node, offset - nodes[current].start)
      }
      for token in XMLSyntax.tokens(bytes) {
        guard let start = place(token.start, opening: true) else { break }
        let first = current
        guard let end = place(token.end, opening: false) else { break }
        let range = document.createRange()
        range.setStart(start.0, start.1)
        range.setEnd(end.0, end.1)
        ranges[token.kind.rawValue].append(range)
        current = first
      }
      editor.ranges = ranges
      editor.colored = true
      paint()
    }

    private static func paint() {
      if highlights.isEmpty {
        for kind in XMLSyntax.Kind.allCases {
          let highlight = Highlight()
          CSS.highlights.set(kind.highlightName, highlight)
          highlights.append(highlight)
        }
      }
      for kind in XMLSyntax.Kind.allCases {
        let highlight = highlights[kind.rawValue]
        highlight.clear()
        for editor in editors where editor.ranges.count > kind.rawValue {
          for range in editor.ranges[kind.rawValue] { highlight.add(range) }
        }
      }
    }
  }
#endif
