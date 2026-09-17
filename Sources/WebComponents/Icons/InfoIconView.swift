import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct InfoIconView: HTMLContent {
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
      // The glyph fills the box: outer ring radius 10 on a 20-unit box, inner
      // radius 7.5, the stem and dot scaled with it (the earlier drawing sat
      // on a 16-unit circle inside a 2-unit margin; every value here is that
      // one mapped through x' = (x − 2) · 1.25).
      path()
        .d(
          M(2.5, 10), a(7.5, 7.5, 0, true, false, 15, 0), a(7.5, 7.5, 0, false, false, -15, 0),
          m(7.5, -10), a(10, 10, 0, true, true, 0, 20), a(10, 10, 0, false, true, 0, -20),
          m(1.25, 8.75), v(6.25), H(8.75), V(8.75), Z(), m(0, -1.25), V(5), H(8.75), v(2.5), Z())
    }
    .class(stringIsEmpty(`class`) ? "info-icon-view" : "info-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 20, 20)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
