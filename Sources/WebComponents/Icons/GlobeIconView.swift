#if SERVER
  import HTMLBuilder
  import SVGBuilder
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import WebTypes

  public struct GlobeIconView: HTMLContent {
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
            M(624.64, 918.53), c(64.51, -102.4, 102.4, -227.84, 109.57, -361.47), h(197.63),
            a(422.91, 422.91, 0, false, true, -307.2, 361.47), M(92.16, 557.06), h(197.63),
            c(7.17, 133.12, 45.06, 259.07, 109.57, 361.47),
            a(422.91, 422.91, 0, false, true, -307.2, -361.47), m(307.2, -451.59),
            c(-64.51, 102.4, -102.4, 227.84, -109.57, 361.99), H(92.16),
            a(422.91, 422.91, 0, false, true, 307.2, -361.99), m(245.25, 451.59),
            A(640, 640, 0, false, true, 512, 921.6), a(640, 640, 0, false, true, -132.61, -365.06),
            Z(), M(378.88, 467.46), A(640, 640, 0, false, true, 512, 101.89),
            a(640, 640, 0, false, true, 132.61, 365.57), Z(), m(552.96, 0), h(-198.14),
            a(757.76, 757.76, 0, false, false, -109.57, -361.99),
            a(422.91, 422.91, 0, false, true, 307.2, 361.99), M(512, 0),
            a(512, 512, 0, true, false, 0, 1024), a(512, 512, 0, false, false, 0, -1024))
      }
      .class(`class`.isEmpty ? "globe-icon-view" : "globe-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
