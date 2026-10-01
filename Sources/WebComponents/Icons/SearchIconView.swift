#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct SearchIconView: HTMLContent {
    let iconSize: CSS.Length

    public init(
      size: CSS.Length
    ) {
      self.iconSize = size
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(
            M(460.8, 51.2), a(409.6, 409.6, 0, true, false, 0, 819.2),
            a(409.6, 409.6, 0, false, false, 0, -819.2), Z())

        path()
          .d(M(972.8, 972.8), l(-222.72, -222.72))
      }
      .class("search-icon-view")
      .style { height(iconSize) }
      .xmlns("http://www.w3.org/2000/svg")
      .viewBox(0, 0, 1024, 1024)
      .fill(.none)
      .stroke(.currentColor)
      .strokeWidth(102.4)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)

    }
  }
#endif
