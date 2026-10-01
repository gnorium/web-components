#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct HelpNoticeIconView: HTMLContent {
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
            M(512, 0), a(512, 512, 0, true, false, 512, 512), A(512, 512, 0, false, false, 512, 0),
            m(51.2, 819.2), H(460.8), v(-102.4), h(102.4), Z(), m(138.75, -389.12),
            a(133.12, 133.12, 0, false, true, -16.89, 37.89),
            a(163.84, 163.84, 0, false, true, -24.58, 28.16), l(-27.65, 24.57),
            c(-10.75, 9.22, -20.99, 17.92, -29.69, 26.63),
            a(128, 128, 0, false, false, -24.07, 28.67),
            A(117.76, 117.76, 0, false, false, 563.2, 614.4),
            a(194.56, 194.56, 0, false, false, -5.63, 51.2), H(464.9),
            a(460.8, 460.8, 0, false, true, 3.58, -64),
            a(168.96, 168.96, 0, false, true, 12.8, -46.08),
            a(143.36, 143.36, 0, false, true, 20.99, -34.3),
            a(204.8, 204.8, 0, false, true, 29.7, -29.7),
            c(8.7, -8.19, 17.41, -15.36, 26.11, -22.53),
            a(153.6, 153.6, 0, false, false, 22.02, -22.53),
            a(92.16, 92.16, 0, false, false, 15.36, -28.16),
            a(102.4, 102.4, 0, false, false, 5.63, -36.86),
            a(107.52, 107.52, 0, false, false, -8.71, -44.03),
            a(87.04, 87.04, 0, false, false, -51.2, -46.08),
            a(87.04, 87.04, 0, false, false, -25.6, -5.12),
            a(90.62, 90.62, 0, false, false, -78.33, 34.81),
            a(153.6, 153.6, 0, false, false, -25.6, 93.19), H(315.39),
            a(240.64, 240.64, 0, false, true, 14.34, -86.02),
            a(184.32, 184.32, 0, false, true, 40.96, -66.05),
            a(199.68, 199.68, 0, false, true, 65.53, -42.49),
            A(235.52, 235.52, 0, false, true, 521.22, 204.8),
            a(225.28, 225.28, 0, false, true, 73.72, 11.78),
            a(179.2, 179.2, 0, false, true, 58.88, 33.28),
            a(158.72, 158.72, 0, false, true, 39.94, 54.27),
            a(179.2, 179.2, 0, false, true, 14.85, 74.24),
            a(174.08, 174.08, 0, false, true, -6.66, 51.71))
      }
      .class(`class`.isEmpty ? "help-notice-icon-view" : "help-notice-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
