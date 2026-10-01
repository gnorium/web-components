#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ConfigureIconView: HTMLContent {
    let iconSize: CSS.Length
    let `class`: String

    public init(
      size: CSS.Length,
      class: String = ""
    ) {
      self.iconSize = size
      self.class = `class`
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .fillRule(.evenodd)
          .d(
            M(113.89, 123.42), V(0), h(113.74), v(123.42),
            a(170.68, 170.68, 0, false, true, 0, 321.9), V(909.97), H(113.89), V(445.32),
            a(170.68, 170.68, 0, false, true, 0, -321.9), M(170.76, 227.49),
            a(56.87, 56.87, 0, true, true, 0, 113.75), a(56.87, 56.87, 0, false, true, 0, -113.75),
            m(625.61, 682.48), v(-350.9), a(170.68, 170.68, 0, false, true, 0, -321.91), V(0),
            h(113.74), v(237.16), a(170.68, 170.68, 0, false, true, 0, 321.91), V(909.97), Z(),
            m(113.74, -511.86), a(56.87, 56.87, 0, true, false, -113.74, 0),
            a(56.87, 56.87, 0, false, false, 113.74, 0))

        path()
          .fillRule(.evenodd)
          .d(
            M(568.87, 521.53), a(170.68, 170.68, 0, false, true, 0, 321.9), V(909.97), H(455.13),
            v(-66.54), a(170.68, 170.68, 0, false, true, 0, -321.9), V(0), h(113.74), Z(),
            M(512, 625.61), a(56.87, 56.87, 0, true, true, 0, 113.74),
            a(56.87, 56.87, 0, false, true, 0, -113.74))
      }
      .class(`class`.isEmpty ? "configure-icon-view" : "configure-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 909.97)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
