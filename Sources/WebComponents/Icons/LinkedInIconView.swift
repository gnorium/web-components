#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct LinkedInIconView: HTMLContent {
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
        // Background rounded square
        path()
          .d(
            M(113.78, 1024), L(910.22, 1024), C(973.06, 1024, 1024, 973.06, 1024, 910.22),
            L(1024, 113.78), C(1024, 50.94, 973.06, 0, 910.22, 0), L(113.78, 0),
            C(50.94, 0, 0, 50.94, 0, 113.78), L(0, 910.22), C(0, 973.06, 50.94, 1024, 113.78, 1024),
            Z())
          .fill(monochrome ? fill : hex(0x007EBB))

        // LinkedIn "in" mark
        path()
          .d(
            M(881.78, 881.78), L(729.82, 881.78), L(729.82, 622.96),
            C(729.82, 552, 702.86, 512.35, 646.69, 512.35),
            C(585.59, 512.35, 553.67, 553.62, 553.67, 622.96), L(553.67, 881.78), L(407.23, 881.78),
            L(407.23, 388.74), L(553.67, 388.74), L(553.67, 455.15),
            C(553.67, 455.15, 597.7, 373.68, 702.33, 373.68),
            C(806.91, 373.68, 881.78, 437.54, 881.78, 569.62), L(881.78, 881.78), Z(),
            M(232.52, 324.18), C(182.64, 324.18, 142.22, 283.44, 142.22, 233.2),
            C(142.22, 182.96, 182.64, 142.22, 232.52, 142.22),
            C(282.41, 142.22, 322.8, 182.96, 322.8, 233.2),
            C(322.8, 283.44, 282.41, 324.18, 232.52, 324.18), Z(), M(156.91, 881.78),
            L(309.61, 881.78), L(309.61, 388.74), L(156.91, 388.74), L(156.91, 881.78), Z())
          .fill(monochrome ? colorInverted : .white)
      }
      .class(`class`.isEmpty ? "linkedin-icon-view" : "linkedin-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .xmlnsXlink("http://www.w3.org/1999/xlink")

    }
  }
#endif
