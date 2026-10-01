#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct EllipsisIconView: HTMLContent {
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
        circle()
          .cx(113.78)
          .cy(512)
          .r(113.78)

        circle()
          .cx(512)
          .cy(512)
          .r(113.78)

        circle()
          .cx(910.22)
          .cy(512)
          .r(113.78)
      }
      .class(`class`.isEmpty ? "ellipsis-icon-view" : "ellipsis-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
