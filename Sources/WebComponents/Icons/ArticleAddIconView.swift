#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ArticleAddIconView: HTMLContent {
    let width: CSS.Length
    let height: CSS.Length
    let `class`: String

    public init(
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      class: String = ""
    ) {
      self.width = width
      self.height = height
      self.class = `class`
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(
            M(227.56, 0), c(-62.58, 0, -113.78, 51.2, -113.78, 113.78), v(796.44),
            c(0, 62.58, 51.2, 113.78, 113.78, 113.78), h(568.88),
            c(62.58, 0, 113.78, -51.2, 113.78, -113.78), V(113.78),
            c(0, -62.58, -51.2, -113.78, -113.78, -113.78), Z(), m(568.88, 568.89), h(-227.55),
            v(227.55), H(455.11), v(-227.55), H(227.56), V(455.11), h(227.55), V(227.56), h(113.78),
            v(227.55), h(227.55), Z())
      }
      .class(`class`.isEmpty ? "article-add-icon-view" : "article-add-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
