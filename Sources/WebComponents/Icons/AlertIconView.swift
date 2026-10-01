import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct AlertIconView: HTMLContent {
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
          M(590.35, 112.31), A(94.74, 94.74, 0, false, false, 512, 56.49),
          A(94.74, 94.74, 0, false, false, 434.16, 112.31), L(18.34, 832.31),
          C(-24.67, 906.57, 10.66, 967.51, 96.18, 967.51), h(831.64),
          c(85.52, 0, 120.85, -60.94, 77.84, -135.2), Z(), M(563.21, 813.88), H(460.79), v(-102.42),
          h(102.42), Z(), m(0, -204.84), H(460.79), V(301.79), h(102.42), Z())
    }
    .class(stringIsEmpty(`class`) ? "alert-icon-view" : "alert-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
