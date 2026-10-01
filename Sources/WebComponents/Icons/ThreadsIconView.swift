#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ThreadsIconView: HTMLContent {
    let `class`: String
    let width: CSS.Length
    let height: CSS.Length
    let fill: CSS.Color
    let monochrome: Bool

    public init(
      class: String = "",
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      fill: CSS.Color = colorBase,
      monochrome: Bool = false
    ) {
      self.class = `class`
      self.width = width
      self.height = height
      self.fill = fill
      self.monochrome = monochrome
    }

    public func build() -> DOM.Node {
      svg {
        // Background rounded square
        path()
          .d(
            M(858.24, 1024), H(165.76), C(74.22, 1024, 0, 949.78, 0, 858.24), V(165.76),
            C(0, 74.22, 74.22, 0, 165.76, 0), h(692.48), C(949.78, 0, 1024, 74.22, 1024, 165.76),
            v(692.48), c(0, 91.54, -74.22, 165.76, -165.76, 165.76), z())
          .fill(monochrome ? fill : .black)

        // Threads icon
        path()
          .d(
            M(431.61, 418.27), c(-12.72, -8.46, -54.97, -37.85, -54.97, -37.85),
            c(35.63, -51.08, 82.62, -70.96, 147.58, -70.96), c(45.95, 0, 84.95, 15.49, 112.8, 44.8),
            c(27.87, 29.32, 43.76, 71.25, 47.37, 124.88), c(15.45, 6.47, 29.71, 14.1, 42.66, 22.82),
            c(52.22, 35.2, 80.98, 87.83, 80.98, 148.17),
            c(0, 128.25, -104.89, 239.65, -294.77, 239.65),
            c(-163.03, 0, -332.41, -95.05, -332.41, -378.08),
            c(0, -281.42, 164.07, -377.51, 331.95, -377.51),
            c(77.53, 0, 259.37, 11.47, 327.75, 237.8), l(-64.12, 16.67),
            C(723.55, 227.41, 612.69, 201.75, 511.05, 201.75),
            c(-168.02, 0, -263.06, 102.54, -263.06, 320.69),
            c(0, 195.61, 106.23, 299.52, 265.29, 299.52),
            c(130.86, 0, 228.43, -68.16, 228.43, -167.93),
            c(0, -67.91, -56.93, -100.42, -59.84, -100.42),
            c(-11.12, 58.26, -40.92, 156.27, -171.75, 156.27),
            c(-76.22, 0, -141.94, -52.77, -141.94, -121.91),
            c(0, -98.73, 93.45, -134.47, 167.25, -134.47), c(27.64, 0, 61, 1.87, 78.36, 5.41),
            c(0, -30.09, -25.4, -81.59, -89.56, -81.59),
            c(-58.82, -0.01, -73.74, 19.12, -92.62, 40.95), z(), m(112.85, 102.67),
            c(-96.14, 0, -108.58, 41.08, -108.58, 66.88), c(0, 41.45, 49.14, 55.19, 75.36, 55.19),
            c(48.07, 0, 97.44, -13.36, 105.21, -114.47),
            c(-24.38, -5.48, -42.54, -7.6, -71.99, -7.6), z())
          .fill(monochrome ? colorInverted : .white)
      }
      .class(`class`.isEmpty ? "threads-icon-view" : "threads-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .xmlnsXlink("http://www.w3.org/1999/xlink")

    }
  }
#endif
