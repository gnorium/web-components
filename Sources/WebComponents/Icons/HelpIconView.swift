#if SERVER
  import HTMLBuilder
  import SVGBuilder
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import WebTypes

  public struct HelpIconView: HTMLContent {
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
            M(287.94, 0.43), C(455.12, 0.43, 568.85, 107.91, 568.85, 258.03),
            a(261.01, 261.01, 0, false, true, -130.22, 232.01),
            c(-80.74, 52.31, -103.49, 87, -103.49, 154.1), V(682.81), H(192.41), v(-46.06),
            a(218.36, 218.36, 0, false, true, 113.73, -218.36),
            c(76.2, -51.18, 101.79, -87.01, 101.79, -154.11),
            a(119.42, 119.42, 0, false, false, -118.28, -121.69), h(-9.67),
            a(130.79, 130.79, 0, false, false, -135.34, 126.24), v(9.67), H(0.2),
            A(267.83, 267.83, 0, false, true, 256.67, 0.43),
            a(284.32, 284.32, 0, false, true, 31.27, 0))

        circle()
          .cx(284.53)
          .cy(910.27)
          .r(113.73)
      }
      .class(`class`.isEmpty ? "help-icon-view" : "help-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 568.93, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
