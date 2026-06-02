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
            M(10, 0), a(10, 10, 0, true, false, 10, 10), A(10, 10, 0, false, false, 10, 0),
            m(5.66, 14.24), l(-1.41, 1.41), L(10, 11.41), l(-4.24, 4.25), l(-1.42, -1.42),
            L(8.59, 10), L(4.34, 5.76), l(1.42, -1.42), L(10, 8.59), l(4.24, -4.24), l(1.41, 1.41),
            L(11.41, 10), Z())
      }
      .class(`class`.isEmpty ? "clear-icon-view" : "clear-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
