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
            M(11.41, 16.58), L(5.83, 11), H(18), V(9), H(5.83), L(11.41, 3.41), L(10, 2), L(2, 10),
            L(10, 18), Z())
      }
      .class(`class`.isEmpty ? "arrow-previous-icon-view" : "arrow-previous-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
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
