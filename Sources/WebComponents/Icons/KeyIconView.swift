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
            M(796.44, 284.44), a(87.61, 87.61, 0, false, true, -85.33, -85.33),
            a(85.33, 85.33, 0, false, true, 170.67, 0),
            A(87.61, 87.61, 0, false, true, 796.44, 284.44), m(-85.33, -284.44),
            A(315.73, 315.73, 0, false, false, 398.22, 312.89),
            a(386.84, 386.84, 0, false, false, 39.82, 159.29), L(0, 910.22), v(113.78), h(227.56),
            v(-113.78), h(113.77), v(-113.78), h(113.78), l(182.05, -182.04),
            a(341.33, 341.33, 0, false, false, 73.95, 11.38),
            A(315.73, 315.73, 0, false, false, 1024, 312.89),
            A(315.73, 315.73, 0, false, false, 711.11, 0))
      }
      .class(`class`.isEmpty ? "key-icon-view" : "key-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
