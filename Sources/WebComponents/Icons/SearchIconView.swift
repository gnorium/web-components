#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct SearchIconView: HTMLContent {
    let width: CSS.Length
    let height: CSS.Length

    public init(
      width: CSS.Length = px(20),
      height: CSS.Length = px(20)
    ) {
      self.width = width
      self.height = height
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(M(11, 3), a(8, 8, 0, true, false, 0, 16), a(8, 8, 0, false, false, 0, -16), Z())

        path()
          .d(m(21, 21), l(-4.35, -4.35))
      }
      .class("search-bar-icon-view")
      .width(width)
      .height(height)
      .xmlns("http://www.w3.org/2000/svg")
      .viewBox(0, 0, 24, 24)
      .fill(.none)
      .stroke(.currentColor)
      .strokeWidth(2)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)

    }
  }
#endif
