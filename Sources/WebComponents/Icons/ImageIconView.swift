#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Codex `image`: a picture frame with a mountain in it.
  public struct ImageIconView: HTMLContent {
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
            M(2, 2), a(2, 2, 0, false, false, -2, 2), v(12), a(2, 2, 0, false, false, 2, 2), h(16),
            a(2, 2, 0, false, false, 2, -2), V(4), a(2, 2, 0, false, false, -2, -2), Z(),
            m(-0.17, 13), l(4.09, -5.25), l(2.92, 3.51), L(12.92, 8), l(5.25, 7), Z())
      }
      .class(`class`.isEmpty ? "image-icon-view" : "image-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
