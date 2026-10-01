import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct InfoIconView: HTMLContent {
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
          M(128, 512), a(384, 384, 0, true, false, 768, 0), a(384, 384, 0, false, false, -768, 0),
          m(384, -512), a(512, 512, 0, true, true, 0, 1024), a(512, 512, 0, false, true, 0, -1024),
          m(64, 448), v(320), H(448), V(448), Z(), m(0, -64), V(256), H(448), v(128), Z())
    }
    .class(stringIsEmpty(`class`) ? "info-icon-view" : "info-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
