#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct LinkExternalIconView: HTMLContent {
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
            M(1024, 0), h(-455.11), l(186.94, 186.94), L(284.44, 625.78), l(78, 83.74),
            l(474, -442.03), l(0.4, 0.46), L(1024, 455.11), Z(), M(56.89, 227.56), h(227.55),
            v(113.77), H(113.78), v(568.89), h(568.89), v(-227.78), h(113.77), V(967.11),
            a(56.89, 56.89, 0, false, true, -56.88, 56.89), H(56.89),
            a(56.89, 56.89, 0, false, true, -56.89, -56.89), V(284.44),
            a(56.89, 56.89, 0, false, true, 56.89, -56.88))
      }
      .class(`class`.isEmpty ? "link-external-icon-view" : "link-external-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
