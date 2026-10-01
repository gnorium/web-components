#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct MergeIconView: HTMLContent {
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
            M(0, 79.64), L(79.64, 0), l(275.92, 274.77),
            A(226.42, 226.42, 0, false, false, 515.98, 341.33), h(290.14), L(716.8, 250.31),
            L(796.44, 170.67), l(227.56, 227.55), l(-227.56, 227.56), l(-79.64, -79.65),
            l(89.88, -91.02), h(-290.13), a(224.71, 224.71, 0, false, false, -160.99, 67.13),
            L(79.64, 796.44), L(0, 716.8), L(318.58, 398.22), Z())
      }
      .class(`class`.isEmpty ? "merge-icon-view" : "merge-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 796.44)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
