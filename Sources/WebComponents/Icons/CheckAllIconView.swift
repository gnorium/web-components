#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct CheckAllIconView: HTMLContent {
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
          .d(
            M(0, 656.43), l(73.77, -73.77), l(115.34, 115.33), l(431.21, -526.8), l(80.01, 65.46),
            l(-503.95, 616.16), Z(), M(608.37, 515.64), h(259.77), v(103.9), h(-259.77), Z(),
            m(-155.86, 207.81), h(259.77), v(103.91), H(452.51), Z(), m(311.72, -415.63), h(259.77),
            v(103.91), h(-259.77), Z())
      }
      .class(`class`.isEmpty ? "check-all-icon-view" : "check-all-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
