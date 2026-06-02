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
            M(236, 0), h(46), l(-101, 115), l(118, 156), h(-92.6), l(-72.5, -94.8), l(-83, 94.8),
            h(-46), l(107, -123), l(-113, -148), h(94.9), l(65.5, 86.6), z(), m(-16.1, 244),
            h(25.5), l(-165, -218), h(-27.4), z()
          )
          .fill(fill)
      }
      .class(`class`.isEmpty ? "x-icon-view" : "x-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 300, 271)
      .xmlns("http://www.w3.org/2000/svg")
      .xmlnsXlink("http://www.w3.org/1999/xlink")

    }
  }
#endif
