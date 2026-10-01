import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct InfoFilledIconView: HTMLContent {
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
          M(512, 0), C(229.22, 0, 0, 229.22, 0, 512), s(229.22, 512, 512, 512),
          s(512, -229.22, 512, -512), S(794.78, 0, 512, 0), M(460.8, 256), h(102.4), v(102.4),
          H(460.8), Z(), m(0, 204.8), h(102.4), v(307.2), H(460.8), Z())
    }
    .class(stringIsEmpty(`class`) ? "info-filled-icon-view" : "info-filled-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
