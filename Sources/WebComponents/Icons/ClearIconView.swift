#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ClearIconView: HTMLContent {
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
            M(512, 0), a(512, 512, 0, true, false, 512, 512), A(512, 512, 0, false, false, 512, 0),
            m(289.79, 729.09), l(-72.19, 72.19), L(512, 584.19), l(-217.09, 217.6), l(-72.7, -72.7),
            L(439.81, 512), L(222.21, 294.91), l(72.7, -72.7), L(512, 439.81), l(217.09, -217.09),
            l(72.19, 72.19), L(584.19, 512), Z())
      }
      .class(`class`.isEmpty ? "clear-icon-view" : "clear-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
