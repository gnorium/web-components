#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ArrowDownIconView: HTMLContent {
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
            M(933.12, 421.76), L(576, 778.88), V(0), H(448), V(778.88), L(90.24, 421.76), L(0, 512),
            L(512, 1024), L(1024, 512), Z())
      }
      .class(`class`.isEmpty ? "arrow-down-icon-view" : "arrow-down-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
