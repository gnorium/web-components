import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import HTMLBuilder
import SVGBuilder
import WebTypes
import EmbeddedSwiftUtilities

public struct NextIconView: HTMLContent {
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
          M(79.64, 0), L(0, 85.33), L(420.98, 512), l(-420.98, 426.67), L(79.64, 1024),
          l(512, -512), Z())
    }
    .class(stringIsEmpty(`class`) ? "next-icon-view" : "next-icon-view \(`class`)")
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
