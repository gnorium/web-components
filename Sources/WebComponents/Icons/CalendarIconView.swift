import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct CalendarIconView: HTMLContent {
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
          M(15, 3), V(1), h(-2), v(2), H(7), V(1), H(5), v(2), H(2),
          a(2, 2, 0, 0, 0, -2, 2), v(12), a(2, 2, 0, 0, 0, 2, 2), h(16),
          a(2, 2, 0, 0, 0, 2, -2), V(5), a(2, 2, 0, 0, 0, -2, -2), z(),
          m(3, 14), H(2), V(8), h(16), z(),
          m(-2, -6), h(-4), v(4), h(4), z())
    }
    .class(stringIsEmpty(`class`) ? "calendar-icon-view" : "calendar-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 20, 20)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
