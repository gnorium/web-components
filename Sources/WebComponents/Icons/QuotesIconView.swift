#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct QuotesIconView: HTMLContent {
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
            M(320, 128), l(64, -128), H(256), C(114.56, 0, 0, 178.56, 0, 320), v(448), h(448),
            V(320), H(192), c(0, -192, 128, -192, 128, -192), m(448, 192),
            c(0, -192, 128, -192, 128, -192), l(64, -128), h(-128),
            c(-141.44, 0, -256, 178.56, -256, 320), v(448), h(448), V(320), Z())
      }
      .class(`class`.isEmpty ? "quotes-icon-view" : "quotes-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 768)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
