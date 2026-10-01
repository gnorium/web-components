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
            M(873.75, 150.86), A(511.51, 511.51, 0, true, false, 985.64, 703.93), h(-141.95),
            a(383.63, 383.63, 0, true, true, -63.93, -461.64), L(576.43, 448.18), h(447.57),
            V(0.61), Z())
      }
      .class(`class`.isEmpty ? "reload-icon-view" : "reload-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
