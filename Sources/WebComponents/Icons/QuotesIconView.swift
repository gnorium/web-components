#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct QuotesIconView: HTMLContent {
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
            M(320, 256), l(64, -128), H(256), C(114.56, 128, 0, 306.56, 0, 448), v(448), h(448),
            V(448), H(192), c(0, -192, 128, -192, 128, -192), m(448, 192),
            c(0, -192, 128, -192, 128, -192), l(64, -128), h(-128),
            c(-141.44, 0, -256, 178.56, -256, 320), v(448), h(448), V(448), Z())
      }
      .class(`class`.isEmpty ? "quotes-icon-view" : "quotes-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
