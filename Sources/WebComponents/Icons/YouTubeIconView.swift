#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct YouTubeIconView: HTMLContent {
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
        // YouTube rounded rectangle background
        path()
          .d(
            M(1002.59, 111.94), C(990.79, 67.86, 956.14, 33.21, 912.06, 21.41),
            C(832.23, 0, 512, 0, 512, 0), C(512, 0, 191.77, 0, 111.94, 21.41),
            C(67.86, 33.21, 33.21, 67.86, 21.41, 111.94), C(0, 191.77, 0, 358.42, 0, 358.42),
            C(0, 358.42, 0, 525.07, 21.41, 604.89), C(33.21, 648.98, 67.86, 683.62, 111.94, 695.42),
            C(191.77, 716.83, 512, 716.83, 512, 716.83),
            C(512, 716.83, 832.23, 716.83, 912.06, 695.42),
            C(956.14, 683.62, 990.79, 648.98, 1002.59, 604.89),
            C(1024, 525.07, 1024, 358.42, 1024, 358.42),
            C(1024, 358.42, 1023.91, 191.77, 1002.59, 111.94), Z())
          .fill(monochrome ? fill : hex(0xFF0000))

        // Play button
        path()
          .d(M(409.5, 512.01), L(675.53, 358.43), L(409.5, 204.85), Z())
          .fill(monochrome ? colorInverted : .white)
      }
      .class(`class`.isEmpty ? "youtube-icon-view" : "youtube-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 716.83)
      .xmlns("http://www.w3.org/2000/svg")

    }
  }
#endif
