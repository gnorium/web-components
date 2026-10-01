#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ViewDetailsIconView: HTMLContent {
    let `class`: String
    let width: CSS.Length
    let height: CSS.Length

    public init(
      class: String = "",
      width: CSS.Length = px(20),
      height: CSS.Length = px(20)
    ) {
      self.class = `class`
      self.width = width
      self.height = height
    }

    public func build() -> DOM.Node {
      svg {
        rect()
          .width(px(358.4))
          .height(px(358.4))
          .x(px(51.2))
          .y(px(51.2))
          .rx(px(51.2))

        rect()
          .width(px(358.4))
          .height(px(358.4))
          .x(px(51.2))
          .y(px(614.4))
          .rx(px(51.2))

        path()
          .d(
            M(614.4, 102.4), h(358.4), M(614.4, 358.4), h(358.4), M(614.4, 665.6), h(358.4),
            M(614.4, 921.6), h(358.4))
      }
      .class(`class`.isEmpty ? "view-details-icon-view" : "view-details-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .strokeWidth(px(102.4))

    }
  }
#endif
