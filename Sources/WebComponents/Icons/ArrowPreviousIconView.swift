#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ArrowPreviousIconView: HTMLContent {
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
            M(602.24, 933.12), L(245.12, 576), H(1024), V(448), H(245.12), L(602.24, 90.24),
            L(512, 0), L(0, 512), L(512, 1024), Z())
      }
      .class(`class`.isEmpty ? "arrow-previous-icon-view" : "arrow-previous-icon-view \(`class`)")
      .width(width)
      .height(height)
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
