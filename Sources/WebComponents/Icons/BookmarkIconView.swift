#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct BookmarkIconView: HTMLContent {
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
            M(227.56, 0), a(113.78, 113.78, 0, false, false, -113.78, 113.78), v(910.22),
            l(398.22, -284.44), l(398.22, 284.44), V(113.78),
            a(113.78, 113.78, 0, false, false, -113.78, -113.78), Z())
      }
      .class(`class`.isEmpty ? "bookmark-icon-view" : "bookmark-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
