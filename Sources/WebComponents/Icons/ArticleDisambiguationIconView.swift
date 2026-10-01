#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ArticleDisambiguationIconView: HTMLContent {
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
            M(796.44, 0), H(227.56), c(-62.58, 0, -113.78, 51.2, -113.78, 113.78), v(341.33),
            h(261.69), l(210.49, -210.49), L(512, 170.67), h(227.56), v(227.55), l(-73.96, -73.95),
            L(477.87, 512), l(187.73, 187.73), L(739.56, 625.78), v(227.55), h(-227.56),
            l(73.96, -73.95), L(375.47, 568.89), H(113.78), v(341.33),
            c(0, 62.58, 51.2, 113.78, 113.78, 113.78), h(568.88),
            c(62.58, 0, 113.78, -51.2, 113.78, -113.78), V(113.78),
            c(0, -62.58, -51.2, -113.78, -113.78, -113.78))
      }
      .class(
        `class`.isEmpty
          ? "article-disambiguation-icon-view" : "article-disambiguation-icon-view \(`class`)"
      )
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
