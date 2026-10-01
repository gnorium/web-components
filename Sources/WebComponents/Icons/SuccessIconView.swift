import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct SuccessIconView: HTMLContent {
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
          M(512, 1024), a(512, 512, 0, false, true, 0, -1024), a(512, 512, 0, true, true, 0, 1024),
          m(-102.4, -256), l(460.8, -435.2), L(793.6, 256), L(409.6, 614.4), L(230.4, 435.2),
          L(153.6, 512), Z())
    }
    .class(stringIsEmpty(`class`) ? "success-icon-view" : "success-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
