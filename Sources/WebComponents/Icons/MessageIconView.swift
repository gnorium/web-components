#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct MessageIconView: HTMLContent {
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
            M(0, 307.2), v(409.6), a(102.4, 102.4, 0, false, false, 102.4, 102.4), h(819.2),
            a(102.4, 102.4, 0, false, false, 102.4, -102.4), V(307.2), l(-512, 204.8), Z())

        path()
          .d(
            M(102.4, 0), a(102.4, 102.4, 0, false, false, -102.4, 102.4), v(102.4), l(512, 204.8),
            l(512, -204.8), V(102.4), a(102.4, 102.4, 0, false, false, -102.4, -102.4), Z())
      }
      .class(`class`.isEmpty ? "message-icon-view" : "message-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 819.2)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
