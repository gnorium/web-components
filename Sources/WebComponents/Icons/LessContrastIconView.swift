#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct LessContrastIconView: HTMLContent {
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
        // Outer circle
        circle()
          .cx(512)
          .cy(512)
          .r(465.45)
          .fill(.none)
          .stroke(.currentColor)
          .strokeWidth(93.09)

        // Inner semicircle (not filled - less contrast)
        path()
          .d(M(512, 791.27), a(279.27, 279.27, 0, false, false, 0, -558.54), v(558.54), Z())
          .fill(.none)
          .stroke(.currentColor)
          .strokeWidth(93.09)
          .strokeLinecap(.round)
          .strokeLinejoin(.round)
      }
      .class(`class`.isEmpty ? "less-contrast-icon-view" : "less-contrast-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .ariaHidden(true)

    }
  }
#endif
