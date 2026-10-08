// Built on both sides: the time input carries it, and the client draws
// time inputs (the filter bar adds fields there).
import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct ClockIconView: HTMLContent {
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
          M(512, 0), a(512, 512, 0, true, false, 512, 512), A(512, 512, 0, false, false, 512, 0),
          m(128, 742.4), L(460.8, 563.2), V(204.8), h(102.4), v(307.2), l(153.6, 153.6), Z())
    }
    .class(stringIsEmpty(`class`) ? "clock-icon-view" : "clock-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)

  }
}
