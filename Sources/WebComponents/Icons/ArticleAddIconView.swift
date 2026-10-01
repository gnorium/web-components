#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ArticleAddIconView: HTMLContent {
    let iconSize: CSS.Length
    let `class`: String

    public init(
      size: CSS.Length,
      class: String = ""
    ) {
      self.iconSize = size
      self.class = `class`
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(
            M(113.78, 0), c(-62.58, 0, -113.78, 51.2, -113.78, 113.78), v(796.44),
            c(0, 62.58, 51.2, 113.78, 113.78, 113.78), h(568.89),
            c(62.57, 0, 113.77, -51.2, 113.77, -113.78), V(113.78),
            c(0, -62.58, -51.2, -113.78, -113.77, -113.78), Z(), m(568.89, 568.89), h(-227.56),
            v(227.55), H(341.33), v(-227.55), H(113.78), V(455.11), h(227.55), V(227.56), h(113.78),
            v(227.55), h(227.56), Z())
      }
      .class(`class`.isEmpty ? "article-add-icon-view" : "article-add-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 796.44, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
