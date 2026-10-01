#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct MoonIconView: HTMLContent {
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
            M(933.65, 801.67), A(415.46, 415.46, 0, false, true, 613.97, 34.23),
            c(13.04, -6.24, 31.74, -13.04, 44.78, -19.27),
            a(464.77, 464.77, 0, false, false, -306.64, 25.5),
            a(510.12, 510.12, 0, true, false, 396.76, 939.75),
            a(477.24, 477.24, 0, false, false, 243.16, -217.65),
            a(300.4, 300.4, 0, false, true, -58.38, 39.11))
      }
      .class(`class`.isEmpty ? "moon-icon-view" : "moon-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
