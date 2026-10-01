#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ListBulletIconView: HTMLContent {
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
            M(341.33, 739.56), h(682.67), v(113.77), H(341.33), Z(), m(0, -341.34), h(682.67),
            v(113.78), H(341.33), Z(), m(0, -341.33), h(682.67), v(113.78), H(341.33), Z())

        circle()
          .cx(113.78)
          .cy(113.78)
          .r(113.78)

        circle()
          .cx(113.78)
          .cy(455.11)
          .r(113.78)

        circle()
          .cx(113.78)
          .cy(796.44)
          .r(113.78)
      }
      .class(`class`.isEmpty ? "list-bullet-icon-view" : "list-bullet-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 910.22)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
