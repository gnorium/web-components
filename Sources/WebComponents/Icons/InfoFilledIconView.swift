#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct InfoFilledIconView: HTMLContent {
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
            M(10, 0), C(4.477, 0, 0, 4.477, 0, 10), s(4.477, 10, 10, 10), s(10, -4.477, 10, -10),
            S(15.523, 0, 10, 0), M(9, 5), h(2), v(2), H(9), Z(), m(0, 4), h(2), v(6), H(9), Z())
      }
      .class(`class`.isEmpty ? "info-filled-icon-view" : "info-filled-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
