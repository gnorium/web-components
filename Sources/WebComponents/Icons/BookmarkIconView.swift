#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct BookmarkIconView: HTMLContent {
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
            M(113.78, 0), a(113.78, 113.78, 0, false, false, -113.78, 113.78), v(910.22),
            l(398.22, -284.44), l(398.22, 284.44), V(113.78),
            a(113.78, 113.78, 0, false, false, -113.77, -113.78), Z())
      }
      .class(`class`.isEmpty ? "bookmark-icon-view" : "bookmark-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 796.44, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
