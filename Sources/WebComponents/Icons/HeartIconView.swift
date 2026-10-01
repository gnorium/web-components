#if SERVER
  import HTMLBuilder
  import SVGBuilder
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import WebTypes

  public struct HeartIconView: HTMLContent {
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
            M(755.2, 52.48), A(268.28, 268.28, 0, false, false, 512.01, 206.08),
            A(268.28, 268.28, 0, false, false, 0.02, 321.28),
            C(0.02, 602.87, 512.01, 974.07, 512.01, 974.07), s(511.99, -371.2, 511.99, -652.79),
            A(268.8, 268.8, 0, false, false, 755.2, 52.48))
      }
      .class(`class`.isEmpty ? "heart-icon-view" : "heart-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
