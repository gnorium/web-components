#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct CheckAllIconView: HTMLContent {
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
            M(0, 485.24), l(73.77, -73.77), l(115.34, 115.34), l(431.21, -526.81), l(80.01, 65.46),
            l(-503.95, 616.17), Z(), M(608.37, 344.45), h(259.77), v(103.91), h(-259.77), Z(),
            m(-155.86, 207.81), h(259.77), v(103.91), H(452.51), Z(), m(311.72, -415.62), h(259.77),
            v(103.9), h(-259.77), Z())
      }
      .class(`class`.isEmpty ? "check-all-icon-view" : "check-all-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 681.63)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
