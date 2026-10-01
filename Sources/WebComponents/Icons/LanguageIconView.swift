#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct LanguageIconView: HTMLContent {
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
            M(1024, 819.2), h(-73.73), a(30.72, 30.72, 0, false, true, -20.48, -6.14),
            a(40.96, 40.96, 0, false, true, -11.77, -15.88), L(870.4, 665.6), h(-256),
            l(-51.2, 130.05), a(40.96, 40.96, 0, false, true, -11.26, 15.36),
            a(30.72, 30.72, 0, false, true, -20.48, 7.17), H(460.8), l(232.96, -587.27), h(96.77),
            Z(), m(-180.74, -220.67), L(762.37, 384),
            a(614.4, 614.4, 0, false, true, -19.97, -63.49), q(-4.61, 18.95, -9.73, 35.33),
            l(-9.73, 28.67), l(-80.89, 214.53), Z(), m(-322.56, -80.9),
            a(686.08, 686.08, 0, false, true, -148.99, -72.19),
            a(586.75, 586.75, 0, false, false, 143.87, -274.94), H(614.4), V(102.4), H(374.27),
            a(204.8, 204.8, 0, false, false, -10.24, -28.67),
            C(351.74, 40.45, 337.92, 0, 337.92, 0), l(-75.26, 25.6), s(20.48, 45.57, 30.72, 76.8),
            H(0), v(68.1), h(110.08), A(574.98, 574.98, 0, false, false, 256, 445.44),
            a(880.64, 880.64, 0, false, true, -256, 107.52), q(28.67, 41.98, 44.54, 70.66),
            a(1192.96, 1192.96, 0, false, false, 267.27, -128.52),
            a(798.72, 798.72, 0, false, false, 182.27, 90.63), Z(), M(185.86, 170.5), h(251.39),
            a(414.72, 414.72, 0, false, true, -125.44, 227.84),
            a(465.92, 465.92, 0, false, true, -125.95, -227.84))
      }
      .class(`class`.isEmpty ? "language-icon-view" : "language-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 819.26)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
