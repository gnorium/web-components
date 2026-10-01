#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct LessContrastIconView: HTMLContent {
    let width: CSS.Length
    let height: CSS.Length
    let `class`: String

    public init(
      width: CSS.Length = px(16),
      height: CSS.Length = px(16),
      class: String = ""
    ) {
      self.width = width
      self.height = height
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
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .ariaHidden(true)

    }
  }
#endif
