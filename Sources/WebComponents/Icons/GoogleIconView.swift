#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct GoogleIconView: HTMLContent {
    let `class`: String
    let width: CSS.Length
    let height: CSS.Length

    public init(
      class: String = "",
      width: CSS.Length = px(20),
      height: CSS.Length = px(20)
    ) {
      self.class = `class`
      self.width = width
      self.height = height
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(
            M(1013.76, 523.64), c(0, -36.31, -3.26, -71.22, -9.31, -104.73), H(522.24), v(198.28),
            h(275.55), c(-12.1, 63.77, -48.41, 117.76, -102.87, 154.07), v(128.93), h(166.17),
            c(96.82, -89.37, 152.67, -220.63, 152.67, -376.55), Z())
          .fill(hex(0x4285F4))
        path()
          .d(
            M(522.24, 1024), c(138.24, 0, 254.14, -45.61, 338.85, -123.81), l(-166.17, -128.93),
            c(-45.61, 30.72, -103.79, 49.34, -172.68, 49.34),
            c(-133.12, 0, -246.23, -89.84, -286.72, -210.85), H(65.16), v(132.18),
            C(149.41, 909.03, 322.09, 1024, 522.24, 1024), Z())
          .fill(hex(0x34A853))
        path()
          .d(
            M(235.52, 609.28), c(-10.24, -30.72, -16.29, -63.3, -16.29, -97.28),
            s(6.05, -66.56, 16.29, -97.28), V(282.53), H(65.16),
            C(30.25, 351.42, 10.24, 429.15, 10.24, 512), s(20.01, 160.58, 54.92, 229.47),
            l(132.66, -103.33), l(37.7, -28.86), Z())
          .fill(hex(0xFBBC05))
        path()
          .d(
            M(522.24, 203.87), c(75.4, 0, 142.43, 26.06, 195.96, 76.33), l(146.61, -146.61),
            C(775.91, 50.73, 660.48, 0, 522.24, 0), C(322.09, 0, 149.41, 114.97, 65.16, 282.53),
            l(170.36, 132.19), c(40.49, -121.02, 153.6, -210.85, 286.72, -210.85), Z())
          .fill(hex(0xEA4335))
      }
      .class(`class`.isEmpty ? "google-icon-view" : "google-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .xmlnsXlink("http://www.w3.org/1999/xlink")

    }
  }
#endif
