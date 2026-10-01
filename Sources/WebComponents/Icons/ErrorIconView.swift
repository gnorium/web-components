import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct ErrorIconView: HTMLContent {
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
          M(724.08, 0), H(299.92), L(0, 299.92), v(424.16), L(299.92, 1024), h(424.16),
          L(1024, 724.08), V(299.92), Z(), M(568.89, 796.44), H(455.11), v(-113.77), h(113.78), Z(),
          m(0, -227.55), H(455.11), V(227.56), h(113.78), Z())
    }
    .class(stringIsEmpty(`class`) ? "error-icon-view" : "error-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
