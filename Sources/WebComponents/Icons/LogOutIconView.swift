#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct LogOutIconView: HTMLContent {
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
            M(113.78, 113.78), h(455.11), V(0), H(113.78),
            a(113.78, 113.78, 0, false, false, -113.78, 113.78), v(796.44),
            a(113.78, 113.78, 0, false, false, 113.78, 113.78), h(455.11), v(-113.78), H(113.78),
            Z())

        path()
          .d(
            M(682.67, 227.56), v(227.55), H(227.56), v(113.78), h(455.11), v(227.55),
            l(341.33, -284.44), Z())
      }
      .class(`class`.isEmpty ? "log-out-icon-view" : "log-out-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
