#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Raw text, shown as code: monospaced, on one quiet code surface, and
  /// colored by the site's syntax tokens rather than by a highlight.js theme.
  ///
  /// The coloring itself happens on the client, and only for a block someone
  /// can actually see—see `CodeHydration`. A document of a few hundred
  /// thousand characters is not worth coloring until it is open.
  public struct CodeView: HTMLContent {
    let text: String
    let language: String
    /// Whether the block is numbered. A file is; a fragment lifted out of one
    /// is not, because its line 1 is not the document's.
    let showLineNumbers: Bool
    /// The text's accessible name when it can be edited in place
    /// (`CodeEditorView`); nil for a block that is only read.
    let editableLabel: String?
    /// Each line its own, numbered (user, 2026-10-12): wide—the lines as
    /// stored, never wrapped, scrolling sideways—unless an ancestor says
    /// Reflow (`[data-reflow='true']`), when a long line wraps as plain
    /// text does, its continuation at column 0 and unnumbered.
    let lined: Bool

    public init(
      _ text: String, language: String = "xml", showLineNumbers: Bool = true, editableLabel: String? = nil,
      lined: Bool = false
    ) {
      self.text = text
      self.language = language
      self.showLineNumbers = showLineNumbers
      self.editableLabel = editableLabel
      self.lined = lined
    }

    /// Read-only syntax is included in the HTML so it does not depend on
    /// visibility observers or the browser's Custom Highlight support.
    private var syntaxTokens: [CodeSyntax.Token] {
      guard let syntax else { return [] }
      let grammar: CodeSyntax.Language = syntax == "xml" ? .xml : (syntax == "json" ? .json : .markdown)
      return CodeSyntax.tokens(Array(text.utf8), language: grammar)
    }

    private func colored(_ range: Range<Int>, units: [UInt16], tokens: [CodeSyntax.Token]) -> [DOM.Node] {
      guard let syntax else { return [DOM.Node.text(String(decoding: units[range], as: UTF16.self))] }
      var nodes: [DOM.Node] = []
      var cursor = range.lowerBound
      for token in tokens where token.end > range.lowerBound && token.start < range.upperBound {
        let start = max(cursor, token.start), end = min(range.upperBound, token.end)
        if cursor < start { nodes.append(DOM.Node.text(String(decoding: units[cursor..<start], as: UTF16.self))) }
        if start < end {
          nodes.append(span { String(decoding: units[start..<end], as: UTF16.self) }.data("code-kind", token.kind.highlightName).build())
          cursor = end
        }
      }
      if cursor < range.upperBound { nodes.append(DOM.Node.text(String(decoding: units[cursor..<range.upperBound], as: UTF16.self))) }
      return nodes
    }

    /// Each line its own block (`lined`), its line feed in it, so the text
    /// reads, copies and edits as written.
    @HTMLBuilder
    private var linedContent: [DOM.Node] {
      let all = CodeLines.lines(of: text)
      var offset = 0
      let units = Array(text.utf16)
      let tokens = syntaxTokens
      for (index, line) in all.enumerated() {
        let value = line.text + (index < all.count - 1 ? "\n" : "")
        let end = offset + value.utf16.count
        span { if editableLabel == nil { colored(offset..<end, units: units, tokens: tokens) } else { DOM.Node.text(value) } }
          .class("code-line")
          .style { customProperty("--indent", "\(line.indent)") }
        offset = end
      }
    }

    /// "1\n2\n3…"—as many as the text has lines.
    static func lineNumbers(of text: String) -> String {
      var out = ""
      var line = 1
      let count = text.split(separator: "\n", omittingEmptySubsequences: false).count
      while line <= count {
        out += line == 1 ? "1" : "\n\(line)"
        line += 1
      }
      return out
    }

    /// The grammar its highlights read it by (`CodeSyntax`): XML, JSON or
    /// Markdown; another language is left to highlight.js.
    private var syntax: String? {
      switch language {
      case "xml", "tei", "html": return "xml"
      case "json": return "json"
      case "markdown", "md": return "markdown"
      default: return nil
      }
    }

    /// The code element, named its grammar when it has one of them.
    private func syntaxed<Element: HTMLElementBuildable>(_ element: Element) -> Element {
      guard let syntax else { return element }
      return element.data("code-syntax", syntax)
    }

    public func build() -> DOM.Node {
      pre {
        // The numbers are a column of their own rather than a counter on each
        // line: a highlighter needs the code to be one run of text, and a
        // wrapped line would put the gutter out of step with it anyway. So the
        // lines do not wrap—they scroll, as they do in an editor—and the
        // gutter stays put while they do.
        if showLineNumbers {
          span { Self.lineNumbers(of: text) }
            .class("code-gutter")
            .ariaHidden(true)
        }

        if lined {
          let numbered = syntaxed(code { linedContent }.class("code-code language-\(language)"))
            .data("code-lined", "true")
            .style { customProperty("--gutter", CodeLines.gutter(lines: CodeLines.lines(of: text).count)) }
          if let editableLabel {
            // Its numbers drawn beside it, never in it: the editable text
            // is the browser's alone, so its undo is never reset
            // (`CodeEditorHydration.number`, measured as CodeMirror does).
            div {}.class("code-gutter-lines").ariaHidden(true)
            numbered
              .addingAttribute("contenteditable", "plaintext-only")
              .spellcheck(false)
              .addingAttribute("autocapitalize", "off")
              .addingAttribute("autocorrect", "off")
              .role("textbox")
              .addingAttribute("aria-multiline", "true")
              .ariaLabel(editableLabel)
              .data("code-editing", "true")
          } else {
            numbered.data("code-colored", "true")
          }
        } else if let editableLabel {
          // The colored text is the text edited: one layer, so a selection
          // is the browser's own over the colors, and a drag past the edge
          // scrolls the pane as any text's does. It is colored by
          // highlights over its text node (`CodeEditorHydration`), never
          // by rewriting it, which would lose the caret.
          syntaxed(code { text }.class("code-code language-\(language)"))
            .addingAttribute("contenteditable", "plaintext-only")
            .spellcheck(false)
            .addingAttribute("autocapitalize", "off")
            .addingAttribute("autocorrect", "off")
            .role("textbox")
            .addingAttribute("aria-multiline", "true")
            .ariaLabel(editableLabel)
            .data("code-editing", "true")
        } else {
          syntaxed(code { colored(0..<text.utf16.count, units: Array(text.utf16), tokens: syntaxTokens) }.class("code-code language-\(language)"))
            .data("code-colored", "true")
        }
      }
      .class("code-view")
      .data("lined", lined)
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.row)
          alignItems(.flexStart)
          gap(spacing12)
          fontFamily(typographyFontMono)
          // CodeEditorView's own size (user, 2026-10-08): code reads at one
          // size whether it can be edited or not, line for line.
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightSmall22)
          color(syntaxPlainText)
          backgroundColor(backgroundColorNeutralSubtle)
          whiteSpace(.pre)
          // Standalone files own horizontal scrolling and rounded clipping.
          // Reader/editor panes override this when they own the scrollport.
          minWidth(0)
          maxWidth(perc(100))
          boxSizing(.borderBox)
          overflowX(.auto)
          borderRadius(borderRadiusBase)
          margin(0)
          padding(spacing16)
        }
        descendant(".code-gutter") {
          position(.sticky)
          insetInlineStart(px(0))
          flexGrow(0)
          flexShrink(0)
          textAlign(.end)
          color(colorSubtle)
          backgroundColor(backgroundColorNeutralSubtle)
          userSelect(.none)
          paddingInlineEnd(spacing8)
          borderInlineEnd(borderWidthBase, .solid, borderColorSubtle)
        }
        descendant(".code-code") {
          flexGrow(0)
          flexShrink(0)
          fontFamily(typographyFontMono)
          backgroundColor(.transparent)
          color(.inherit)
          padding(0)
        }
        // Lined: each line a block, numbered in a gutter by a counter
        // (never part of the text). Wide: the lines as stored, never
        // wrapped, scrolling sideways.
        selector("&[data-lined='true'] .code-code") {
          CSS.Property("counter-reset", "code-line")
        }
        selector("&[data-lined='true'] .code-line") {
          display(.block)
          position(.relative)
          CSS.Property("counter-increment", "code-line")
          CSS.Property("min-height", "1lh")
          CSS.Property("padding-inline-start", "calc(var(--gutter) + \(spacing12.value))")
        }
        // Reflowed (an ancestor's Reflow, user 2026-10-12): wrapped as plain
        // text, no sideways scroll; a continuation starts at column 0, no
        // indent inherited or added, and has no number.
        selector("[data-reflow='true'] &[data-lined='true']") {
          whiteSpace(.preWrap)
          overflowX(.visible)
        }
        selector("[data-reflow='true'] &[data-lined='true'] .code-code") {
          flexShrink(1)
          minWidth(0)
          width(perc(100))
        }
        selector("[data-reflow='true'] &[data-lined='true'] .code-line") {
          overflowWrap(.anywhere)
        }
        // An editor numbers its lines in a gutter of its own, measured: a
        // line typed into a line's block is a line of its own.
        selector("&[data-lined='true']:has(.code-gutter-lines)") { position(.relative) }
        selector("&[data-lined='true'] .code-code[data-code-editing='true'] .code-line::before") {
          CSS.Property("content", "none")
        }
        descendant(".code-gutter-lines") {
          position(.absolute)
          insetBlockStart(px(0))
          insetInlineStart(px(0))
          pointerEvents(.none)
          userSelect(.none)
          color(colorSubtle)
        }
        descendant(".code-gutter-lines > span") {
          position(.absolute)
          insetInlineStart(px(0))
          textAlign(.end)
        }
        selector("&[data-lined='true'] .code-line::before") {
          CSS.Property("content", "counter(code-line)")
          position(.absolute)
          insetInlineStart(px(0))
          CSS.Property("width", "var(--gutter)")
          textAlign(.end)
          color(colorSubtle)
          userSelect(.none)
        }
        // Text colored by highlights (`CodeSyntax`): an editor, and every
        // XML, JSON or Markdown block, by its grammar's roles.
        CodeSyntax.highlightCSS("& .code-code")
        // Another language's, by highlight.js's classes, in the same roles:
        // a tag's marks plain, its name a keyword, attribute names and
        // values their own, declarations as preprocessor statements.
        // `descendant(a, b)` nests one selector inside the other, so each of
        // these is its own rule: they are alternatives, not a path.
        descendant(".hljs-tag") { color(syntaxPlainText).important() }
        descendant(".hljs-name") { color(syntaxKeywords).important() }
        descendant(".hljs-attr") { color(syntaxAttributes).important() }
        descendant(".hljs-attribute") { color(syntaxAttributes).important() }
        descendant(".hljs-string") { color(syntaxStrings).important() }
        descendant(".hljs-comment") { color(syntaxComments).important() }
        descendant(".hljs-meta") { color(syntaxPreprocessorStatements).important() }
        descendant(".hljs-symbol") { color(syntaxPlainText).important() }
        descendant(".hljs-punctuation") { color(syntaxPlainText).important() }
      }
      .build()
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes

  /// Colors the code blocks someone can see, when they can see them.
  ///
  /// A page may hold a thousand blocks—one per page of a transcription—behind
  /// switches, accordions and a viewer's pager. Coloring them all at
  /// load would spend a second of the main thread on markup nobody has asked
  /// for, so nothing happens until a block has a box on screen: at load, after
  /// any click that may have opened one, and whenever an object viewer turns to
  /// another canvas. A block already colored is left alone.
  public final class CodeHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: CodeHydration?

    public static func hydrateIfPresent() {
      guard document.querySelector(".code-view, [data-code-syntax]") != nil else { return }
      hydrate(in: document.body)
    }

    public init() {}

    /// The code blocks under `root`, which may be a fragment swapped in
    /// after the page's own pass. The page-wide click is listened to once, by
    /// whichever pass comes first; each viewer under `root` is listened to by
    /// this one, because a viewer that arrives later is a new element.
    public static func hydrate(in root: DOM.Element) {
      if instance == nil {
        _ = document.addEventListener(.click) { _ in
          _ = window.requestAnimationFrame { Self.highlightVisible() }
        }
        instance = CodeHydration()
      }
      for viewer in root.querySelectorAll(".artifact-view") {
        _ = viewer.addEventListener("artifact-canvas-change") { _ in
          Self.highlightVisible()
        }
        // A page fetched into the reader after it turned (a windowed
        // reader's, the Revise page's), and XML switched on however it was
        // pressed: colored once it is laid out (user, 2026-10-14), not at
        // the next click.
        _ = viewer.addEventListener("artifact-markup-added") { _ in
          _ = window.requestAnimationFrame { Self.highlightVisible() }
        }
        _ = viewer.querySelector(".artifact-xml-toggle")?.addEventListener("toggle-button-update") { _ in
          _ = window.requestAnimationFrame { Self.highlightVisible() }
        }
      }
      highlightVisible()
    }

    public static func highlightVisible() {
      for block in document.querySelectorAll(".code-code, [data-code-syntax]") {
        // An editor's text is colored by highlights, which leave it whole.
        if block.hasAttribute("data-code-editing") {
          CodeEditorHydration.colorIfVisible(block)
          continue
        }
        // So is every XML, JSON or Markdown block, a Raw's among them: by
        // its grammar's roles (`CodeSyntax`), which highlight.js lacks.
        if block.hasAttribute("data-code-syntax") {
          CodeEditorHydration.colorTextIfVisible(block)
          continue
        }
        // highlight.js writes data-highlighted="yes" itself, which overwrote the
        // "true" this used to look for—so every block was highlighted again on
        // every click, and highlight.js warned each time that it had been handed
        // markup it had written. Any value at all means done.
        guard stringIsEmpty(block.dataset["highlighted"] ?? "") else { continue }
        guard let rect = block.getBoundingClientRect(), rect.height > 0 else { continue }
        block.setAttribute(data("highlighted"), "yes")
        HighlightJS.highlightElement(elementID: block.id)
      }
    }
  }
#endif

/// A text's lines for lined code (`CodeView.lined`), server and client
/// alike: split by bytes, never by `Character`, which Embedded Swift
/// cannot compare.
public enum CodeLines {
  /// The text's lines, each with the spaces (or tabs) it is indented by.
  public static func lines(of text: String) -> [(text: String, indent: Int)] {
    var out: [(text: String, indent: Int)] = []
    var current: [UInt8] = []
    var indent = 0
    var leading = true
    for byte in text.utf8 {
      if byte == 0x0A {
        out.append((String(decoding: current, as: UTF8.self), indent))
        current = []
        indent = 0
        leading = true
        continue
      }
      if leading && (byte == 0x20 || byte == 0x09) { indent += 1 } else { leading = false }
      current.append(byte)
    }
    out.append((String(decoding: current, as: UTF8.self), indent))
    return out
  }

  /// The gutter's width for so many lines: a character a digit.
  public static func gutter(lines count: Int) -> String {
    var digits = 1
    var rest = count
    while rest >= 10 {
      digits += 1
      rest /= 10
    }
    return String(decoding: [UInt8(0x30 + digits)], as: UTF8.self) + "ch"
  }
}
