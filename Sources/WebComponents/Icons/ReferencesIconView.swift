#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ReferencesIconView: HTMLContent {
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
          .d(
            M(0, 36.02), v(823.32), h(257.29), V(36.02), Z(), m(205.83, 617.49), H(51.46),
            v(-51.46), h(154.37), Z(), m(0, -154.37), H(51.46), v(-51.46), h(154.37), Z(),
            m(102.91, -463.12), v(823.32), h(257.29), V(36.02), Z(), m(205.83, 617.49), H(360.2),
            v(-51.46), h(154.37), Z(), m(0, -154.37), H(360.2), v(-51.46), h(154.37), Z(),
            m(51.46, -437.39), l(210.97, 792.44), l(247, -66.89), l(-205.83, -787.3), Z(),
            m(360.2, 545.45), l(-149.23, 41.16), l(-15.43, -51.46), l(149.22, -41.16), Z(),
            m(-41.16, -149.23), l(-149.23, 41.17), l(-10.29, -51.46), l(149.22, -41.17), Z())
      }
      .class(`class`.isEmpty ? "references-icon-view" : "references-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 859.34)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
