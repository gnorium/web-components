#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct AppleIconView: HTMLContent {
    let `class`: String
    let width: CSS.Length
    let height: CSS.Length
    let fill: CSS.Color

    public init(
      class: String = "",
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      fill: CSS.Color = extreme
    ) {
      self.class = `class`
      self.width = width
      self.height = height
      self.fill = fill
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(
            M(518.49, 294.23), c(-40.45, 0, -103.04, -46, -168.96, -44.38),
            c(-87.04, 1.16, -166.83, 50.48, -211.67, 128.6),
            c(-90.33, 156.8, -23.3, 388.39, 64.81, 515.84),
            c(43.22, 62.03, 94.21, 131.84, 161.79, 129.66),
            c(64.85, -2.77, 89.17, -42.11, 167.89, -42.11),
            c(78.12, 0, 100.27, 42.11, 168.96, 40.45),
            c(69.85, -1.11, 114.18, -63.15, 156.84, -125.78),
            c(49.32, -72.02, 69.8, -141.87, 70.91, -145.71),
            c(-1.66, -0.55, -135.76, -52.1, -137.38, -207.23),
            c(-1.11, -129.71, 105.81, -191.74, 110.8, -194.52),
            c(-60.97, -89.17, -154.58, -99.15, -187.3, -101.37),
            c(-85.34, -6.66, -156.8, 46.5, -196.69, 46.5), Z(), M(662.61, 163.41),
            c(35.97, -43.18, 59.74, -103.55, 53.12, -163.41),
            c(-51.5, 2.22, -113.58, 34.35, -150.7, 77.57),
            c(-33.28, 38.23, -62.03, 99.75, -54.31, 158.46),
            c(57.09, 4.44, 115.84, -29.35, 151.85, -72.58))
          .fill(fill)
      }
      .class(`class`.isEmpty ? "apple-icon-view" : "apple-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .xmlnsXlink("http://www.w3.org/1999/xlink")

    }
  }
#endif
