#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct DarkModeIconView: HTMLContent {
    let `class`: String
    let width: Length
    let height: Length

    public init(
      class: String = "",
      width: Length = px(16),
      height: Length = px(16)
    ) {
      self.class = `class`
      self.width = width
      self.height = height
    }

    public func build() -> Node {
      svg {
        path()
          .d(M(8, 2), a(4, 4, 0, false, false, 6, 6), a(6, 6, 0, true, true, -6, -6), Z())
          .strokeWidth(1.5)
          .strokeLinecap(.round)
          .strokeLinejoin(.round)
      }
      .class(`class`.isEmpty ? "dark-mode-icon-view" : "dark-mode-icon-view \(`class`)")
      .xmlns("http://www.w3.org/2000/svg")
      .width(width)
      .height(height)
      .viewBox(0, 0, 16, 16)
      .fill(.none)
      .stroke(.currentColor)

    }
  }
#endif
