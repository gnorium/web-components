#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct FullscreenIconView: HTMLContent {
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
        // Top-left corner bracket
        path()
          .d(M(1, 1), V(7), H(3), V(3), H(7), V(1), Z())
        // Bottom-left corner bracket
        path()
          .d(M(3, 13), H(1), V(19), H(7), V(17), H(3), Z())
        // Bottom-right corner bracket
        path()
          .d(M(17, 17), H(13), V(19), H(19), V(13), H(17), Z())
        // Top-right corner bracket
        path()
          .d(M(17, 1), H(13), V(3), H(17), V(7), H(19), V(1), Z())
      }
      .class(`class`.isEmpty ? "fullscreen-icon-view" : "fullscreen-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
