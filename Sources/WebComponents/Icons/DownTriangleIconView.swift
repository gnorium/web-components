#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct DownTriangleIconView: HTMLContent {
    let width: Length
    let height: Length
    let `class`: String

    public init(
      width: Length = px(20),
      height: Length = px(20),
      class: String = ""
    ) {
      self.width = width
      self.height = height
      self.class = `class`
    }

    public func render() -> Node {
      svg {
        path()
          .d(M(10, 15), L(2, 5), h(16), Z())
      }
      .class(`class`.isEmpty ? "down-triangle-icon-view" : "down-triangle-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
