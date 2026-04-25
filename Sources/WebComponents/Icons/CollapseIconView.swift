#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct CollapseIconView: HTMLContent {
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
          .d(m(2.5, 15.25), l(7.5, -7.5), l(7.5, 7.5), l(1.5, -1.5), l(-9, -9), l(-9, 9), Z())
      }
      .class(`class`.isEmpty ? "collapse-icon-view" : "collapse-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
