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
          .cx(12)
          .cy(12)
          .r(10)
          .fill(.none)
          .stroke(.currentColor)
          .strokeWidth(2)

        // Inner semicircle (not filled - less contrast)
        path()
          .d(M(12, 18), a(6, 6, 0, false, false, 0, -12), v(12), Z())
          .fill(.none)
          .stroke(.currentColor)
          .strokeWidth(2)
          .strokeLinecap(.round)
          .strokeLinejoin(.round)
      }
      .class(`class`.isEmpty ? "less-contrast-icon-view" : "less-contrast-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 24, 24)
      .xmlns("http://www.w3.org/2000/svg")
      .ariaHidden(true)

    }
  }
#endif
