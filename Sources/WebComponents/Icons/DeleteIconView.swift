#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct DeleteIconView: HTMLContent {
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
        path()
          .d(
            M(884.36, 186.18), H(372.36), l(-325.81, 325.82), l(325.81, 325.82), h(512),
            a(93.09, 93.09, 0, false, false, 93.09, -93.09), V(279.27),
            a(93.09, 93.09, 0, false, false, -93.09, -93.09), Z(), M(791.27, 372.36),
            l(-279.27, 279.28), M(512, 372.36), l(279.27, 279.28))
      }
      .class(`class`.isEmpty ? "delete-icon-view" : "delete-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .strokeWidth(px(93.09))

    }
  }
#endif
