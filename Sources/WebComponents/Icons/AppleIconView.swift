#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct AppleIconView: HTMLContent {
    let `class`: String
    let iconSize: CSS.Length
    let fill: CSS.Color

    public init(
      class: String = "",
      size: CSS.Length,
      fill: CSS.Color = extreme
    ) {
      self.class = `class`
      self.iconSize = size
      self.fill = fill
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(
            M(423.55, 294.23), c(-40.45, 0, -103.04, -46, -168.96, -44.38),
            c(-87.04, 1.16, -166.82, 50.48, -211.67, 128.6),
            c(-90.32, 156.8, -23.29, 388.39, 64.81, 515.84),
            c(43.22, 62.03, 94.21, 131.84, 161.79, 129.66),
            c(64.86, -2.77, 89.18, -42.11, 167.9, -42.11),
            c(78.12, 0, 100.26, 42.11, 168.96, 40.45),
            c(69.84, -1.11, 114.17, -63.15, 156.84, -125.78),
            c(49.32, -72.02, 69.8, -141.87, 70.91, -145.71),
            c(-1.67, -0.55, -135.77, -52.1, -137.39, -207.23),
            c(-1.11, -129.71, 105.82, -191.74, 110.81, -194.52),
            c(-60.97, -89.17, -154.58, -99.15, -187.31, -101.37),
            c(-85.33, -6.66, -156.8, 46.5, -196.69, 46.5), Z(), M(567.68, 163.41),
            c(35.96, -43.18, 59.73, -103.55, 53.12, -163.41),
            c(-51.5, 2.22, -113.58, 34.35, -150.7, 77.57),
            c(-33.28, 38.23, -62.04, 99.75, -54.32, 158.46),
            c(57.09, 4.44, 115.84, -29.35, 151.85, -72.58))
          .fill(fill)
      }
      .class(`class`.isEmpty ? "apple-icon-view" : "apple-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 834.13, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .xmlnsXlink("http://www.w3.org/1999/xlink")

    }
  }
#endif
