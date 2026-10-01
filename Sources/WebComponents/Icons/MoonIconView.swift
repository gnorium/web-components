#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct MoonIconView: HTMLContent {
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
            M(901.67, 801.67), A(415.46, 415.46, 0, false, true, 582, 34.23),
            c(13.04, -6.24, 31.74, -13.04, 44.78, -19.27),
            a(464.77, 464.77, 0, false, false, -306.64, 25.5),
            a(510.12, 510.12, 0, true, false, 396.76, 939.75),
            a(477.24, 477.24, 0, false, false, 243.15, -217.65),
            a(300.4, 300.4, 0, false, true, -58.38, 39.11))
      }
      .class(`class`.isEmpty ? "moon-icon-view" : "moon-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 960.05, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
