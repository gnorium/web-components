#if SERVER
  import HTMLBuilder
  import SVGBuilder
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import WebTypes

  public struct HeartIconView: HTMLContent {
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
            M(755.2, 2.55), A(268.28, 268.28, 0, false, false, 512.01, 156.15),
            A(268.28, 268.28, 0, false, false, 0.02, 271.35),
            C(0.02, 552.94, 512.01, 924.14, 512.01, 924.14), s(511.99, -371.2, 511.99, -652.79),
            A(268.8, 268.8, 0, false, false, 755.2, 2.55))
      }
      .class(`class`.isEmpty ? "heart-icon-view" : "heart-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 924.14)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
