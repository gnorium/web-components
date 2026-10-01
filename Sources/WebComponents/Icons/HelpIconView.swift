#if SERVER
  import HTMLBuilder
  import SVGBuilder
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import WebTypes

  public struct HelpIconView: HTMLContent {
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
            M(515.48, 0.43), C(682.66, 0.43, 796.39, 107.91, 796.39, 258.03),
            a(261.01, 261.01, 0, false, true, -130.22, 232.01),
            c(-80.75, 52.31, -103.49, 87, -103.49, 154.1), V(682.81), H(419.95), v(-46.06),
            a(218.36, 218.36, 0, false, true, 113.73, -218.36),
            c(76.19, -51.18, 101.78, -87.01, 101.78, -154.11),
            a(119.42, 119.42, 0, false, false, -118.28, -121.69), h(-9.66),
            a(130.79, 130.79, 0, false, false, -135.34, 126.24), v(9.67), H(227.74),
            A(267.83, 267.83, 0, false, true, 484.2, 0.43),
            a(284.32, 284.32, 0, false, true, 31.28, 0))

        circle()
          .cx(512.07)
          .cy(910.27)
          .r(113.73)
      }
      .class(`class`.isEmpty ? "help-icon-view" : "help-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
