#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ShareIconView: HTMLContent {
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
            M(625.78, 227.56), V(0), l(398.22, 398.22), l(-398.22, 398.22), v(-227.55),
            c(-284.45, 0, -483.56, 85.33, -625.78, 284.44), l(45.51, -170.66), l(11.38, -22.76),
            A(682.67, 682.67, 0, false, true, 625.78, 227.56))
      }
      .class(`class`.isEmpty ? "share-icon-view" : "share-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 853.33)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
