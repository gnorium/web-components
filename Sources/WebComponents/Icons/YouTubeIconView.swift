#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct YouTubeIconView: HTMLContent {
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
        // YouTube rounded rectangle background
        path()
          .d(
            M(1002.59, 265.53), C(990.79, 221.44, 956.14, 186.8, 912.06, 174.99),
            C(832.23, 153.58, 512, 153.58, 512, 153.58),
            C(512, 153.58, 191.77, 153.58, 111.94, 174.99),
            C(67.86, 186.8, 33.21, 221.44, 21.41, 265.53), C(0, 345.35, 0, 512, 0, 512),
            C(0, 512, 0, 678.65, 21.41, 758.48), C(33.21, 802.56, 67.86, 837.21, 111.94, 849),
            C(191.77, 870.42, 512, 870.42, 512, 870.42),
            C(512, 870.42, 832.23, 870.42, 912.06, 849),
            C(956.14, 837.21, 990.79, 802.56, 1002.59, 758.48),
            C(1024, 678.65, 1024, 512, 1024, 512), C(1024, 512, 1023.91, 345.35, 1002.59, 265.53),
            Z())
          .fill(monochrome ? fill : hex(0xFF0000))

        // Play button
        path()
          .d(M(409.5, 665.6), L(675.53, 512.01), L(409.5, 358.43), Z())
          .fill(monochrome ? colorInverted : .white)
      }
      .class(`class`.isEmpty ? "youtube-icon-view" : "youtube-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")

    }
  }
#endif
