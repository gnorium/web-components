#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ArticleIconView: HTMLContent {
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
            M(113.78, 0), a(113.78, 113.78, 0, false, false, -113.78, 113.78), v(796.44),
            a(113.78, 113.78, 0, false, false, 113.78, 113.78), h(568.89),
            a(113.78, 113.78, 0, false, false, 113.77, -113.78), V(113.78),
            a(113.78, 113.78, 0, false, false, -113.77, -113.78), Z(), m(0, 170.67), h(284.44),
            v(56.89), H(113.78), Z(), m(0, 113.77), h(284.44), v(56.89), H(113.78), Z(),
            m(0, 113.78), h(284.44), v(56.89), H(113.78), Z(), m(568.89, 398.22), H(113.78),
            v(-56.88), h(568.89), Z(), m(0, -113.77), H(113.78), v(-56.89), h(568.89), Z(),
            m(0, -113.78), H(113.78), v(-56.89), h(568.89), Z(), m(0, -113.78), h(-227.56),
            V(170.67), h(227.56), Z())
      }
      .class(`class`.isEmpty ? "article-icon-view" : "article-icon-view \(`class`)")
      .viewBox(0, 0, 796.44, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
      .style {
        height(iconSize)
        display(.block)
        flexShrink(0)
      }

    }
  }
#endif
