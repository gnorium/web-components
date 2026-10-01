#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct MessageIconView: HTMLContent {
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
            M(0, 409.6), v(409.6), a(102.4, 102.4, 0, false, false, 102.4, 102.4), h(819.2),
            a(102.4, 102.4, 0, false, false, 102.4, -102.4), V(409.6), l(-512, 204.8), Z())

        path()
          .d(
            M(102.4, 102.4), a(102.4, 102.4, 0, false, false, -102.4, 102.4), v(102.4),
            l(512, 204.8), l(512, -204.8), V(204.8),
            a(102.4, 102.4, 0, false, false, -102.4, -102.4), Z())
      }
      .class(`class`.isEmpty ? "message-icon-view" : "message-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
