#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct DarkModeIconView: HTMLContent {
    let `class`: String
    let iconSize: CSS.Length

    public init(
      class: String = "",
      size: CSS.Length
    ) {
      self.class = `class`
      self.iconSize = size
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(
            M(512, 56.89), a(303.4, 303.4, 0, false, false, 455.11, 455.11),
            a(455.11, 455.11, 0, true, true, -455.11, -455.11), Z())
          .strokeWidth(113.78)
          .strokeLinecap(.round)
          .strokeLinejoin(.round)
      }
      .class(`class`.isEmpty ? "dark-mode-icon-view" : "dark-mode-icon-view \(`class`)")
      .xmlns("http://www.w3.org/2000/svg")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .fill(.none)
      .stroke(.currentColor)

    }
  }
#endif
