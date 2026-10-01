import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct CalendarIconView: HTMLContent {
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
          M(768, 102.4), V(0), h(-102.4), v(102.4), H(358.4), V(0), H(256), v(102.4), H(102.4),
          a(102.4, 102.4, 0, 0, 0, -102.4, 102.4), v(614.4), a(102.4, 102.4, 0, 0, 0, 102.4, 102.4),
          h(819.2), a(102.4, 102.4, 0, 0, 0, 102.4, -102.4), V(204.8),
          a(102.4, 102.4, 0, 0, 0, -102.4, -102.4), z(), m(153.6, 716.8), H(102.4), V(358.4),
          h(819.2), z(), m(-102.4, -307.2), h(-204.8), v(204.8), h(204.8), z())
    }
    .class(stringIsEmpty(`class`) ? "calendar-icon-view" : "calendar-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 921.6)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
