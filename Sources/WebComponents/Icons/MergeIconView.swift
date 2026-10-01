#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct MergeIconView: HTMLContent {
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
            M(0, 193.42), L(79.64, 113.78), l(275.92, 274.77),
            A(226.42, 226.42, 0, false, false, 515.98, 455.11), h(290.14), L(716.8, 364.09),
            L(796.44, 284.44), l(227.56, 227.56), l(-227.56, 227.56), l(-79.64, -79.65),
            l(89.88, -91.02), h(-290.13), a(224.71, 224.71, 0, false, false, -160.99, 67.13),
            L(79.64, 910.22), L(0, 830.58), L(318.58, 512), Z())
      }
      .class(`class`.isEmpty ? "merge-icon-view" : "merge-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
