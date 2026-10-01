import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct AlertIconView: HTMLContent {
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
          M(590.35, 55.82), A(94.74, 94.74, 0, false, false, 512, 0),
          A(94.74, 94.74, 0, false, false, 434.16, 55.82), L(18.34, 775.82),
          C(-24.67, 850.07, 10.66, 911.01, 96.18, 911.01), h(831.64),
          c(85.52, 0, 120.85, -60.94, 77.84, -135.19), Z(), M(563.21, 757.38), H(460.79),
          v(-102.41), h(102.42), Z(), m(0, -204.83), H(460.79), V(245.29), h(102.42), Z())
    }
    .class(stringIsEmpty(`class`) ? "alert-icon-view" : "alert-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 911.01)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
