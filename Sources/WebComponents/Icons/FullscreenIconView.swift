#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct FullscreenIconView: HTMLContent {
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
        // Top-left corner bracket
        path()
          .d(M(0, 0), V(341.33), H(113.78), V(113.78), H(341.33), V(0), Z())
        // Bottom-left corner bracket
        path()
          .d(M(113.78, 682.67), H(0), V(1024), H(341.33), V(910.22), H(113.78), Z())
        // Bottom-right corner bracket
        path()
          .d(M(910.22, 910.22), H(682.67), V(1024), H(1024), V(682.67), H(910.22), Z())
        // Top-right corner bracket
        path()
          .d(M(910.22, 0), H(682.67), V(113.78), H(910.22), V(341.33), H(1024), V(0), Z())
      }
      .class(`class`.isEmpty ? "fullscreen-icon-view" : "fullscreen-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
