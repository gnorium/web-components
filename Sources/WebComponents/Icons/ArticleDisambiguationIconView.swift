#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ArticleDisambiguationIconView: HTMLContent {
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
            M(682.67, 0), H(113.78), c(-62.58, 0, -113.78, 51.2, -113.78, 113.78), v(341.33),
            h(261.69), l(210.49, -210.49), L(398.22, 170.67), h(227.56), v(227.55),
            l(-73.96, -73.95), L(364.09, 512), l(187.73, 187.73), L(625.78, 625.78), v(227.55),
            h(-227.56), l(73.96, -73.95), L(261.69, 568.89), H(0), v(341.33),
            c(0, 62.58, 51.2, 113.78, 113.78, 113.78), h(568.89),
            c(62.57, 0, 113.77, -51.2, 113.77, -113.78), V(113.78),
            c(0, -62.58, -51.2, -113.78, -113.77, -113.78))
      }
      .class(
        `class`.isEmpty
          ? "article-disambiguation-icon-view" : "article-disambiguation-icon-view \(`class`)"
      )
      .style { height(iconSize) }
      .viewBox(0, 0, 796.44, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
