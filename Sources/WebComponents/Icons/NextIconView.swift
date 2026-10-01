import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import HTMLBuilder
import SVGBuilder
import WebTypes
import EmbeddedSwiftUtilities

public struct NextIconView: HTMLContent {
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
          M(295.82, 0), L(216.18, 85.33), L(637.16, 512), l(-420.98, 426.67), L(295.82, 1024),
          l(512, -512), Z())
    }
    .class(stringIsEmpty(`class`) ? "next-icon-view" : "next-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
    // Next and previous are directions along the line, not left and right:
    // in a right-to-left page the line's end is on the left.
    .style {
      selector("&") {
        pseudoClass(.dir("rtl")) { scale(-1, 1) }
      }
    }

  }
}
