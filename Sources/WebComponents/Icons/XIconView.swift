#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct XIconView: HTMLContent {
    let `class`: String
    let iconSize: CSS.Length
    let fill: CSS.Color
    let monochrome: Bool

    public init(
      class: String = "",
      size: CSS.Length,
      fill: CSS.Color = colorBase,
      monochrome: Bool = false
    ) {
      self.class = `class`
      self.iconSize = size
      self.fill = fill
      self.monochrome = monochrome
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(
            M(809.03, 0), h(156.96), l(-344.63, 392.4), l(402.64, 532.31), h(-315.97),
            l(-247.38, -323.48), l(-283.22, 323.48), h(-156.96), l(365.11, -419.71),
            l(-385.58, -505), h(323.82), l(223.5, 295.5), z(), m(-54.93, 832.58), h(87.01),
            l(-563.02, -743.86), h(-93.49), z())
          .fill(fill)
      }
      .class(`class`.isEmpty ? "x-icon-view" : "x-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 924.71)
      .xmlns("http://www.w3.org/2000/svg")
      .xmlnsXlink("http://www.w3.org/1999/xlink")

    }
  }
#endif
