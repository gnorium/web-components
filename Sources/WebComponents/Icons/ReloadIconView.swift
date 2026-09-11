#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Circular reload / rerun mark (Codex `reload.svg`).
  public struct ReloadIconView: HTMLContent {
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
            M(15.65, 4.35), A(8, 8, 0, true, false, 17.4, 13), h(-2.22),
            a(6, 6, 0, true, true, -1, -7.22), L(11, 9), h(7), V(2), Z()
          )
      }
      .class(`class`.isEmpty ? "reload-icon-view" : "reload-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
