#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct PreviousIconView: HTMLContent {
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
          .d(m(4, 10), l(9, 9), l(1.4, -1.5), L(7, 10), l(7.4, -7.5), L(13, 1), Z())
      }
      .class(`class`.isEmpty ? "previous-icon-view" : "previous-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
