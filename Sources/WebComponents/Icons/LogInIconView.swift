#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct LogInIconView: HTMLContent {
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
            M(0, 568.89), v(341.33), c(0, 62.58, 51.2, 113.78, 113.78, 113.78), h(796.44),
            c(62.58, 0, 113.78, -51.2, 113.78, -113.78), V(113.78),
            c(0, -62.58, -51.2, -113.78, -113.78, -113.78), H(113.78),
            c(-62.58, 0, -113.78, 51.2, -113.78, 113.78), v(341.33), h(455.11), V(227.56),
            l(270.22, 284.44), L(455.11, 796.44), v(-227.55), Z())
      }
      .class(`class`.isEmpty ? "log-in-icon-view" : "log-in-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
