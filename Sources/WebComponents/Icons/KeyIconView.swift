#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Codex `key` icon.
  public struct KeyIconView: HTMLContent {
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
            M(15, 6), a(1.54, 1.54, 0, false, true, -1.5, -1.5), a(1.5, 1.5, 0, false, true, 3, 0),
            A(1.54, 1.54, 0, false, true, 15, 6), m(-1.5, -5), A(5.55, 5.55, 0, false, false, 8, 6.5),
            a(6.8, 6.8, 0, false, false, 0.7, 2.8), L(1, 17), v(2), h(4), v(-2), h(2), v(-2), h(2), l(3.2, -3.2),
            a(6, 6, 0, false, false, 1.3, 0.2), A(5.55, 5.55, 0, false, false, 19, 6.5),
            A(5.55, 5.55, 0, false, false, 13.5, 1))
      }
      .class(`class`.isEmpty ? "key-icon-view" : "key-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
