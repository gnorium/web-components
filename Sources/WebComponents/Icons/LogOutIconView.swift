#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct LogOutIconView: HTMLContent {
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
            M(3, 3), h(8), V(1), H(3), a(2, 2, 0, false, false, -2, 2), v(14),
            a(2, 2, 0, false, false, 2, 2), h(8), v(-2), H(3), Z())

        path()
          .d(M(13, 5), v(4), H(5), v(2), h(8), v(4), l(6, -5), Z())
      }
      .class(`class`.isEmpty ? "log-out-icon-view" : "log-out-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
