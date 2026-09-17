#if SERVER
  import DOMBuilder
  import HTMLBuilder
  import MarkdownUtilities
  import WebTypes

  /// Markdown, rendered.
  ///
  /// `MarkdownRenderer.render` returns an HTML *string*, and a string in an
  /// `@HTMLBuilder` block is text: the builder escapes it, so a call site passing
  /// the renderer's output straight in would print `<p>` on the page instead of a
  /// paragraph. Wrapping each such call in `raw(_:)` would put an unescaped-HTML
  /// hatch into everyday view code, one copy-paste away from a value that should
  /// have been escaped.
  ///
  /// A view instead: the markup is markup because of its *type*, the trust is
  /// declared once, here, and the call site reads like every other component.
  ///
  ///     div {
  ///       MarkdownView(thinking)
  ///     }
  ///     .class("session-output-thinking-rendered")
  public struct MarkdownView: HTMLContent {
    let markdown: String

    public init(_ markdown: String) {
      self.markdown = markdown
    }

    public func build() -> DOM.Node {
      HTMLText(content: MarkdownRenderer.render(markdown), isRaw: true)
    }
  }
#endif
