#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ListBulletIconView: HTMLContent {
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
            M(341.33, 796.44), h(682.67), v(113.78), H(341.33), Z(), m(0, -341.33), h(682.67),
            v(113.78), H(341.33), Z(), m(0, -341.33), h(682.67), v(113.78), H(341.33), Z())

        circle()
          .cx(113.78)
          .cy(170.67)
          .r(113.78)

        circle()
          .cx(113.78)
          .cy(512)
          .r(113.78)

        circle()
          .cx(113.78)
          .cy(853.33)
          .r(113.78)
      }
      .class(`class`.isEmpty ? "list-bullet-icon-view" : "list-bullet-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
