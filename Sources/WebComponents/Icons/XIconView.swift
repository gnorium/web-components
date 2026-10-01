#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct XIconView: HTMLContent {
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
        path()
          .d(
            M(809.03, 49.65), h(156.96), l(-344.63, 392.4), l(402.64, 532.3), h(-315.97),
            l(-247.38, -323.47), l(-283.22, 323.47), h(-156.96), l(365.11, -419.7),
            l(-385.58, -505), h(323.82), l(223.5, 295.49), z(), m(-54.93, 832.57), h(87.01),
            l(-563.02, -743.86), h(-93.49), z())
          .fill(fill)
      }
      .class(`class`.isEmpty ? "x-icon-view" : "x-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .xmlnsXlink("http://www.w3.org/1999/xlink")

    }
  }
#endif
