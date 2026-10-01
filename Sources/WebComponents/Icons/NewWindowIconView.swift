#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct NewWindowIconView: HTMLContent {
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
            M(910.22, 910.22), H(113.78), V(113.78), h(284.44), V(0), H(113.78),
            a(113.78, 113.78, 0, false, false, -113.78, 113.78), v(796.44),
            a(113.78, 113.78, 0, false, false, 113.78, 113.78), h(796.44),
            a(113.78, 113.78, 0, false, false, 113.78, -113.78), v(-284.44), h(-113.78), Z())

        path()
          .d(
            M(568.89, 0), l(187.16, 187.16), l(-325.97, 325.98), l(80.78, 80.78),
            l(325.98, -325.97), L(1024, 455.11), V(0), Z())
      }
      .class(`class`.isEmpty ? "new-window-icon-view" : "new-window-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
