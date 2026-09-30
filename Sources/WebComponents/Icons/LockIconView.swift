#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Codex `lock` icon.
  public struct LockIconView: HTMLContent {
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
            M(16.07, 8), H(15), V(5), s(0, -5, -5, -5), s(-5, 5, -5, 5), v(3), H(3.93),
            A(1.93, 1.93, 0, false, false, 2, 9.93), v(8.15), A(1.93, 1.93, 0, false, false, 3.93, 20), h(12.14),
            A(1.93, 1.93, 0, false, false, 18, 18.07), V(9.93), A(1.93, 1.93, 0, false, false, 16.07, 8),
            M(10, 16), a(2, 2, 0, true, true, 2, -2), a(2, 2, 0, false, true, -2, 2),
            m(3, -8), H(7), V(5.5), C(7, 4, 7, 2, 10, 2), s(3, 2, 3, 3.5), Z())
      }
      .class(`class`.isEmpty ? "lock-icon-view" : "lock-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
