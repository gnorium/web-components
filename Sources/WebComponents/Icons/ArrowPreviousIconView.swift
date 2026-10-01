#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ArrowPreviousIconView: HTMLContent {
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
            M(602.24, 933.12), L(245.12, 576), H(1024), V(448), H(245.12), L(602.24, 90.24),
            L(512, 0), L(0, 512), L(512, 1024), Z())
      }
      .class(`class`.isEmpty ? "arrow-previous-icon-view" : "arrow-previous-icon-view \(`class`)")
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
