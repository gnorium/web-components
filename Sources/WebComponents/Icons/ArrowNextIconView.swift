#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ArrowNextIconView: HTMLContent {
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
            M(421.76, 90.88), L(778.88, 448), H(0), v(128), h(778.88), l(-357.12, 357.76),
            L(512, 1024), l(512, -512), l(-512, -512), Z())
      }
      .class(`class`.isEmpty ? "arrow-next-icon-view" : "arrow-next-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
      // Next and previous are directions along the line, not left and
      // right: in a right-to-left page the line's end is on the left.
      .style {
        selector("&") {
          pseudoClass(.dir("rtl")) { scale(-1, 1) }
        }
      }

    }
  }
#endif
