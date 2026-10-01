#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import SVGBuilder
  import HTMLBuilder
  import DOMBuilder
  import WebTypes

  public struct MenuIconView: HTMLContent {
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
            M(0, 0), v(113.78), h(1024), V(0), Z(), M(0, 455.11), h(1024), V(341.33), H(0), Z(),
            M(0, 796.44), h(1024), v(-113.77), H(0), Z())
      }
      .class(`class`.isEmpty ? "menu-icon-view" : "menu-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 796.44)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
