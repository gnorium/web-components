#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Circular reload / rerun mark (Codex `reload.svg`).
  public struct ReloadIconView: HTMLContent {
    let iconSize: CSS.Length
    let `class`: String

    public init(
      size: CSS.Length,
      class: String = ""
    ) {
      self.iconSize = size
      self.class = `class`
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(
            M(873.75, 150.37), A(511.51, 511.51, 0, true, false, 985.64, 703.43), h(-141.95),
            a(383.63, 383.63, 0, true, true, -63.93, -461.63), L(576.43, 447.68), h(447.57),
            V(0.11), Z())
      }
      .class(`class`.isEmpty ? "reload-icon-view" : "reload-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 1023.01)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
