#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct BookIconView: HTMLContent {
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
            M(796.44, 0), a(435.2, 435.2, 0, false, false, -284.44, 113.78),
            a(435.2, 435.2, 0, false, false, -284.44, -113.78), H(0), v(853.33), h(227.56),
            a(435.2, 435.2, 0, false, true, 284.44, 113.78),
            a(435.2, 435.2, 0, false, true, 284.44, -113.78), h(227.56), V(0), Z(), m(142.23, 768),
            H(739.56), a(249.17, 249.17, 0, false, false, -170.67, 56.89), V(170.67),
            s(56.89, -85.34, 227.55, -85.34), h(142.23), Z())

        path()
          .d(M(455.11, 85.33), h(113.78), v(56.89), H(455.11), Z())
      }
      .class(`class`.isEmpty ? "book-icon-view" : "book-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 967.11)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
