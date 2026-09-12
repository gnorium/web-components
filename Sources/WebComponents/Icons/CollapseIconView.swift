import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Collapse / compress glyph. Available on SERVER + CLIENT: the live trace
/// builds the compaction card with it, as the server does.
public struct CollapseIconView: HTMLContent {
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
        .d(m(2.5, 15.25), l(7.5, -7.5), l(7.5, 7.5), l(1.5, -1.5), l(-9, -9), l(-9, 9), Z())
    }
    .class(stringIsEmpty(`class`) ? "collapse-icon-view" : "collapse-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 20, 20)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)

  }
}
