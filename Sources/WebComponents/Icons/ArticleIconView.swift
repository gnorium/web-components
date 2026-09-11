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
            M(5, 1), a(2, 2, 0, false, false, -2, 2), v(14), a(2, 2, 0, false, false, 2, 2), h(10),
            a(2, 2, 0, false, false, 2, -2), V(3), a(2, 2, 0, false, false, -2, -2), Z(), m(0, 3),
            h(5), v(1), H(5), Z(), m(0, 2), h(5), v(1), H(5), Z(), m(0, 2), h(5), v(1), H(5), Z(),
            m(10, 7), H(5), v(-1), h(10), Z(), m(0, -2), H(5), v(-1), h(10), Z(), m(0, -2), H(5),
            v(-1), h(10), Z(), m(0, -2), h(-4), V(4), h(4), Z())
      }
      .class(`class`.isEmpty ? "article-icon-view" : "article-icon-view \(`class`)")
      .width(20)
      .height(20)
      .viewBox(0, 0, 20, 20)
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
