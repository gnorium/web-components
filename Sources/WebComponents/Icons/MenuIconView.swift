#if SERVER
  import SVGBuilder
  import HTMLBuilder
  import DOMBuilder
  import WebTypes

  public struct MenuIconView: HTMLContent {
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
            M(0, 113.78), v(113.78), h(1024), V(113.78), Z(), M(0, 568.89), h(1024), V(455.11),
            H(0), Z(), M(0, 910.22), h(1024), v(-113.78), H(0), Z())
      }
      .class(`class`.isEmpty ? "menu-icon-view" : "menu-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
