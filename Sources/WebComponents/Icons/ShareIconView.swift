#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ShareIconView: HTMLContent {
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
            M(625.78, 312.89), V(85.33), l(398.22, 398.23), l(-398.22, 398.22), v(-227.56),
            c(-284.45, 0, -483.56, 85.34, -625.78, 284.45), l(45.51, -170.67), l(11.38, -22.76),
            A(682.67, 682.67, 0, false, true, 625.78, 312.89))
      }
      .class(`class`.isEmpty ? "share-icon-view" : "share-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
