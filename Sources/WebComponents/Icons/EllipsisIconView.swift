#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct EllipsisIconView: HTMLContent {
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
        circle()
          .cx(113.78)
          .cy(113.78)
          .r(113.78)

        circle()
          .cx(512)
          .cy(113.78)
          .r(113.78)

        circle()
          .cx(910.22)
          .cy(113.78)
          .r(113.78)
      }
      .class(`class`.isEmpty ? "ellipsis-icon-view" : "ellipsis-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 227.56)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
