#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ConfigureIconView: HTMLContent {
    let width: CSS.Length
    let height: CSS.Length
    let `class`: String

    public init(
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      class: String = ""
    ) {
      self.width = width
      self.height = height
      self.class = `class`
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .fillRule(.evenodd)
          .d(
            M(113.89, 180.43), V(57.01), h(113.74), v(123.42),
            a(170.68, 170.68, 0, false, true, 0, 321.9), V(966.99), H(113.89), V(502.33),
            a(170.68, 170.68, 0, false, true, 0, -321.9), M(170.76, 284.51),
            a(56.87, 56.87, 0, true, true, 0, 113.74), a(56.87, 56.87, 0, false, true, 0, -113.74),
            m(625.61, 682.48), v(-350.91), a(170.68, 170.68, 0, false, true, 0, -321.91), V(57.01),
            h(113.74), v(237.16), a(170.68, 170.68, 0, false, true, 0, 321.91), V(966.99), Z(),
            m(113.74, -511.86), a(56.87, 56.87, 0, true, false, -113.74, 0),
            a(56.87, 56.87, 0, false, false, 113.74, 0))

        path()
          .fillRule(.evenodd)
          .d(
            M(568.87, 578.54), a(170.68, 170.68, 0, false, true, 0, 321.91), V(966.99), H(455.13),
            v(-66.54), a(170.68, 170.68, 0, false, true, 0, -321.91), V(57.01), h(113.74), Z(),
            M(512, 682.62), a(56.87, 56.87, 0, true, true, 0, 113.75),
            a(56.87, 56.87, 0, false, true, 0, -113.75))
      }
      .class(`class`.isEmpty ? "configure-icon-view" : "configure-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
