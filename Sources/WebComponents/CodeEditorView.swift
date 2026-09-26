#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Raw text, edited where it is read.
  ///
  /// A `CodeView` of the text, coloured as every code block on the site
  /// is, with a textarea laid exactly over it. The textarea's own glyphs are
  /// transparent, so the colours underneath show through, while its caret and
  /// selection stay on top; as the text changes the client copies it into the
  /// block and colours it again. The two share one font, one line height and
  /// no padding, so each character of the one sits on its twin in the other,
  /// and neither wraps: the container scrolls, as a code block's does.
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
        CodeView(value, language: language, showLineNumbers: false)
        textarea(value)
          .id(id)
          .name(name)
          .wrap("off")
          .spellcheck(false)
          .addingAttribute("autocapitalize", "off")
          .autocomplete("off")
          .ariaLabel(ariaLabel)
          .class("code-editor-input")
      }
      .class("code-editor-view")
      .style {
        selector("&") {
          display(.grid)
          minWidth(0)
        }
        // One cell, both layers in it: the block sizes the cell to the text,
        // and the textarea stretches over exactly that.
        selector("& > .code-view", "& > .code-editor-input") {
          gridArea("1 / 1")
        }
        descendant(".code-editor-input") {
          fontFamily(typographyFontMono)
          fontSize(fontSizeXSmall12)
          lineHeight(lineHeightXSmall20)
          whiteSpace(.pre)
          margin(0)
          padding(0)
          border(.none)
          outline(.none)
          resize(.none)
          overflow(.hidden)
          backgroundColor(.transparent)
          color(.transparent)
          caretColor(colorBase)
          minWidth(0)
        }
        descendant(".code-editor-input::selection") {
          backgroundColor(backgroundColorBlueSubtle)
          color(.transparent)
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

  /// Keeps each editor's coloured block in step with its textarea: the text
  /// copied across at once, so the block keeps the size the textarea needs,
  /// and coloured again a moment after typing stops.
  public enum CodeEditorHydration {
    /// The editors under `root` that nothing is keeping in step yet.
    public static func hydrate(in root: DOM.Element) {
      for view in root.querySelectorAll(".code-editor-view") {
        if view.hasAttribute("data-code-editor-hydrated") { continue }
        view.setAttribute(data("code-editor-hydrated"), "true")
        guard let input = view.querySelector(".code-editor-input") as? HTML.HTMLTextAreaElement,
          let code = view.querySelector(".code-view-code")
        else { continue }
        let pending = Pending()
        _ = input.addEventListener(.input) { _ in
          // A final newline draws no line in a block; a space after it does,
          // so the caret on the new last line has a line under it.
          let text = input.value
          code.textContent = stringEndsWith(text, "\n") ? stringJoin([text, " "], separator: "") : text
          code.removeAttribute(data("highlighted"))
          if pending.timer != 0 { window.clearTimeout(pending.timer) }
          pending.timer = window.setTimeout(300) {
            pending.timer = 0
            code.setAttribute(data("highlighted"), "yes")
            HighlightJS.highlightElement(elementID: code.id)
          }
        }
      }
    }

    /// The colouring waiting for typing to stop.
    private final class Pending: @unchecked Sendable {
      var timer: Int32 = 0
    }
  }
#endif
