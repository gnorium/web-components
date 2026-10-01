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
      path()
        .d(
          M(128, 512), a(384, 384, 0, true, false, 768, 0), a(384, 384, 0, false, false, -768, 0),
          m(384, -512), a(512, 512, 0, true, true, 0, 1024), a(512, 512, 0, false, true, 0, -1024),
          m(64, 448), v(320), H(448), V(448), Z(), m(0, -64), V(256), H(448), v(128), Z())
    }
    .class(stringIsEmpty(`class`) ? "info-icon-view" : "info-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
