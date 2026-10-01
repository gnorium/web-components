#if SERVER
  import SVGBuilder
  import HTMLBuilder
  import DOMBuilder
  import WebTypes

  public struct MoveLastIconView: HTMLContent {
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
            M(782.22, 0), h(113.78), v(1024), h(-113.78), Z(), M(128, 85.33), L(554.67, 512),
            l(-426.67, 426.67), L(213.33, 1024), l(512, -512), l(-512, -512), Z())
      }
      .class(`class`.isEmpty ? "move-last-icon-view" : "move-last-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
