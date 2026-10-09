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

    public init(id: String, name: String, value: String, language: String = "xml", ariaLabel: String) {
      self.id = id
      self.name = name
      self.value = value
      self.language = language
      self.ariaLabel = ariaLabel
    }

    public func build() -> DOM.Node {
      div {
        CodeView(value, language: language, showLineNumbers: false, editableLabel: ariaLabel)
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
        // The colors `CodeView`'s highlight.js classes give, by highlight.
        selector("& .code-code::highlight(code-tag)") { color(syntaxPlainText) }
        selector("& .code-code::highlight(code-name)") { color(syntaxKeywords) }
        selector("& .code-code::highlight(code-attr)") { color(syntaxAttributes) }
        selector("& .code-code::highlight(code-string)") { color(syntaxStrings) }
        selector("& .code-code::highlight(code-comment)") { color(syntaxComments) }
        selector("& .code-code::highlight(code-meta)") { color(syntaxOtherDeclarations) }
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
      let input: HTML.HTMLTextAreaElement
      var ranges: [[DOM.Range]] = []
      var colored = false
      var timer: Int32 = 0

      init(code: DOM.Element, input: HTML.HTMLTextAreaElement) {
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
          code.textContent = text
          schedule(editor)
        }
        colorIfVisible(code)
      }
    }

    /// Colors an editor's text the first time it has a box on screen.
    public static func colorIfVisible(_ code: DOM.Element) {
      guard let editor = editors.first(where: { $0.code.id == code.id }), !editor.colored,
        let rect = code.getBoundingClientRect(), rect.height > 0
      else { return }
      color(editor)
    }

    private static func schedule(_ editor: Editor) {
      if editor.timer != 0 { window.clearTimeout(editor.timer) }
      editor.timer = window.setTimeout(150) {
        editor.timer = 0
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
