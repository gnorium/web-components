import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct DeleteIconView: HTMLContent {
  let `class`: String
  let iconSize: CSS.Length

  public init(
    class: String = "",
    size: CSS.Length
  ) {
    self.class = `class`
    self.iconSize = size
  }

  public func build() -> DOM.Node {
    svg {
      path()
        .d(
          M(884.36, 46.55), H(372.36), l(-325.81, 325.81), l(325.81, 325.82), h(512),
          a(93.09, 93.09, 0, false, false, 93.09, -93.09), V(139.64),
          a(93.09, 93.09, 0, false, false, -93.09, -93.09), Z(), M(791.27, 232.73),
          l(-279.27, 279.27), M(512, 232.73), l(279.27, 279.27))
    }
    .class(stringIsEmpty(`class`) ? "delete-icon-view" : "delete-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 744.73)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.none)
    .stroke(.currentColor)
    .strokeLinecap(.round)
    .strokeLinejoin(.round)
    .strokeWidth(px(93.09))

  }
}
