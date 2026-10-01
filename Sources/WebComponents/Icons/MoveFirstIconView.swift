#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct MoveFirstIconView: HTMLContent {
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
            M(0, 0), h(113.78), v(1024), H(0), Z(), m(768, 85.33), L(682.67, 0), l(-512, 512),
            l(512, 512), l(85.33, -85.33), L(341.33, 512), Z())
      }
      .class(`class`.isEmpty ? "move-first-icon-view" : "move-first-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 768, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
