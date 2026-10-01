import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Collapse / compress glyph. Available on SERVER + CLIENT: the live trace
/// builds the compaction card with it, as the server does.
public struct CollapseIconView: HTMLContent {
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
          M(85.33, 597.33), l(426.67, -426.66), l(426.67, 426.66), l(85.33, -85.33), l(-512, -512),
          l(-512, 512), Z())
    }
    .class(stringIsEmpty(`class`) ? "collapse-icon-view" : "collapse-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 597.33)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)

  }
}
