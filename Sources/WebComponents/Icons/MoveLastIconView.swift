#if SERVER
  import SVGBuilder
  import HTMLBuilder
  import DOMBuilder
  import WebTypes

  public struct MoveLastIconView: HTMLContent {
    let width: Length
    let height: Length
    let `class`: String

    public init(
      width: Length = px(20),
      height: Length = px(20),
      class: String = ""
    ) {
      self.width = width
      self.height = height
      self.class = `class`
    }

    public func build() -> Node {
      svg {
        path()
          .d(
            M(15, 1), h(2), v(18), h(-2), Z(), M(3.5, 2.5), L(11, 10), l(-7.5, 7.5), L(5, 19),
            l(9, -9), l(-9, -9), Z())
      }
      .class(`class`.isEmpty ? "move-last-icon-view" : "move-last-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
