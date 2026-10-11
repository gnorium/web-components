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

    /// Each line its own block (`lined`), its line feed in it, so the text
    /// reads, copies and edits as written.
    @HTMLBuilder
    private var linedContent: [DOM.Node] {
      let all = CodeLines.lines(of: text)
      for (index, line) in all.enumerated() {
        span { line.text + (index < all.count - 1 ? "\n" : "") }
          .class("code-line")
          .style { customProperty("--indent", "\(line.indent)") }
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
          let numbered = code { linedContent }
            .class("code-code language-\(language)")
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
            numbered
          }
        } else if let editableLabel {
          // The colored text is the text edited: one layer, so a selection
          // is the browser's own over the colors, and a drag past the edge
          // scrolls the pane as any text's does. It is colored by
          // highlights over its text node (`CodeEditorHydration`), never
          // by rewriting it, which would lose the caret.
          code { text }
            .class("code-code language-\(language)")
            .addingAttribute("contenteditable", "plaintext-only")
            .spellcheck(false)
            .addingAttribute("autocapitalize", "off")
            .addingAttribute("autocorrect", "off")
            .role("textbox")
            .addingAttribute("aria-multiline", "true")
            .ariaLabel(editableLabel)
            .data("code-editing", "true")
        } else {
          code { text }
            .class("code-code language-\(language)")
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
          borderInlineEnd(borderWidthBase, .solid, borderColorBase)
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
        // Text colored by highlights (an editor, lined text), by XML's
        // grammar (`XMLSyntax`), in the palette highlight.js's classes take
        // below, as VS Code's and Xcode's defaults map it: a tag's marks
        // (`<`, `</`, `>`, `/>`) plain, its name a keyword, attribute names
        // and values their own, references as characters; text plain.
        selector("& .code-code::highlight(code-tag)") { color(syntaxPlainText) }
        selector("& .code-code::highlight(code-name)") { color(syntaxKeywords) }
        selector("& .code-code::highlight(code-attr)") { color(syntaxAttributes) }
        selector("& .code-code::highlight(code-string)") { color(syntaxStrings) }
        selector("& .code-code::highlight(code-comment)") { color(syntaxComments) }
        selector("& .code-code::highlight(code-meta)") { color(syntaxOtherDeclarations) }
        selector("& .code-code::highlight(code-entity)") { color(syntaxCharacters) }
        selector("& .code-code::highlight(code-cdata)") { color(syntaxStrings) }
        // One palette for code across the site: the same tokens the session
        // trace colors a tool call's markup with.
        // `descendant(a, b)` nests one selector inside the other, so each of
        // these is its own rule: they are alternatives, not a path.
        descendant(".hljs-tag") { color(syntaxPlainText).important() }
        descendant(".hljs-name") { color(syntaxKeywords).important() }
        descendant(".hljs-attr") { color(syntaxAttributes).important() }
        descendant(".hljs-attribute") { color(syntaxAttributes).important() }
        descendant(".hljs-string") { color(syntaxStrings).important() }
        descendant(".hljs-comment") { color(syntaxComments).important() }
        descendant(".hljs-meta") { color(syntaxOtherDeclarations).important() }
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
      guard document.querySelector(".code-view") != nil else { return }
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
      }
      highlightVisible()
    }

    public static func highlightVisible() {
      for block in document.querySelectorAll(".code-code") {
        // An editor's text is colored by highlights, which leave it whole.
        if block.hasAttribute("data-code-editing") {
          CodeEditorHydration.colorIfVisible(block)
          continue
        }
        // So is lined text: highlight.js would rewrite its lines away.
        if block.hasAttribute("data-code-lined") {
          CodeEditorHydration.colorLinedIfVisible(block)
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
