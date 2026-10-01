import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import HTMLBuilder
import SVGBuilder
import WebTypes
import EmbeddedSwiftUtilities

public struct PreviousIconView: HTMLContent {
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
          M(0, 512), l(512, 512), l(79.64, -85.33), L(170.67, 512), l(420.97, -426.67), L(512, 0),
          Z())
    }
    .class(stringIsEmpty(`class`) ? "previous-icon-view" : "previous-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 591.64, 1024)
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
