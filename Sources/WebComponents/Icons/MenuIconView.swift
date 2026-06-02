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
            M(1, 3), v(2), h(18), V(3), Z(),
            M(1, 11), h(18), V(9), H(1), Z(),
            M(1, 17), h(18), v(-2), H(1), Z())
      }
      .class(`class`.isEmpty ? "menu-icon-view" : "menu-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
