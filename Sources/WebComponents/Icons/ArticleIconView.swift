#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ArticleIconView: HTMLContent {
    let iconWidth: CSS.Length
    let iconHeight: CSS.Length
    let `class`: String

    public init(
      width: CSS.Length = size44,
      height: CSS.Length = size44,
      class: String = ""
    ) {
      self.iconWidth = width
      self.iconHeight = height
      self.class = `class`
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(
            M(227.56, 0), a(113.78, 113.78, 0, false, false, -113.78, 113.78), v(796.44),
            a(113.78, 113.78, 0, false, false, 113.78, 113.78), h(568.88),
            a(113.78, 113.78, 0, false, false, 113.78, -113.78), V(113.78),
            a(113.78, 113.78, 0, false, false, -113.78, -113.78), Z(), m(0, 170.67), h(284.44),
            v(56.89), H(227.56), Z(), m(0, 113.77), h(284.44), v(56.89), H(227.56), Z(),
            m(0, 113.78), h(284.44), v(56.89), H(227.56), Z(), m(568.88, 398.22), H(227.56),
            v(-56.88), h(568.88), Z(), m(0, -113.77), H(227.56), v(-56.89), h(568.88), Z(),
            m(0, -113.78), H(227.56), v(-56.89), h(568.88), Z(), m(0, -113.78), h(-227.55),
            V(170.67), h(227.55), Z())
      }
      .class(`class`.isEmpty ? "article-icon-view" : "article-icon-view \(`class`)")
      .width(20)
      .height(20)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
      .style {
        selector("&") {
          width(iconWidth)
          height(iconHeight)
          display(.block)
          flexShrink(0)
        }
      }

    }
  }
#endif
