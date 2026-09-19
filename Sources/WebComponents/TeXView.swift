#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import TeXUtilities
  import WebTypes

  /// A TeX formula with readable source until the browser typesets it.
  public struct TeXView: HTMLContent {
    let source: String
    let displayMode: Bool

    public init(_ source: String, displayMode: Bool = false) {
      self.source = source
      self.displayMode = displayMode
    }

    public func build() -> DOM.Node {
      span {
        // The package escapes source text before emitting this HTML fragment.
        HTMLText(content: TeXRenderer.placeholder(source, displayMode: displayMode), isRaw: true)
      }
      .class("tex-view")
      .style {
        descendant(".tex-formula") {
          whiteSpace(.preWrap)
        }
        selector("& .tex-formula[data-tex-display='display']") {
          display(.block)
          maxWidth(perc(100))
          overflowX(.auto)
          paddingBlock(spacing4)
        }
      }
      .build()
    }
  }
#endif
