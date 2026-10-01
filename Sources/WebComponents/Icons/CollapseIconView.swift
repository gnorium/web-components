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
        .d(
          M(85.33, 810.67), l(426.67, -426.67), l(426.67, 426.67), l(85.33, -85.34), l(-512, -512),
          l(-512, 512), Z())
    }
    .class(stringIsEmpty(`class`) ? "collapse-icon-view" : "collapse-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)

  }
}
