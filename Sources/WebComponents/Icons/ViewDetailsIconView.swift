#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ViewDetailsIconView: HTMLContent {
    let `class`: String
    let width: Length
    let height: Length

    public init(
      class: String = "",
      width: Length = px(18),
      height: Length = px(18)
    ) {
      self.class = `class`
      self.width = width
      self.height = height
    }

    public func build() -> Node {
      svg {
        rect()
          .width(px(7))
          .height(px(7))
          .x(px(3))
          .y(px(3))
          .rx(px(1))

        rect()
          .width(px(7))
          .height(px(7))
          .x(px(3))
          .y(px(14))
          .rx(px(1))

        path()
          .d(M(14, 4), h(7), M(14, 9), h(7), M(14, 15), h(7), M(14, 20), h(7))
      }
      .class(`class`.isEmpty ? "view-details-icon-view" : "view-details-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 24, 24)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .strokeWidth(px(2))

    }
  }
#endif
