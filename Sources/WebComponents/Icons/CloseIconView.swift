import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Codex `close` icon: the ✕ of a close or dismiss button. Available on
/// SERVER + CLIENT (client code renders it: `StatusIconView` shows how).
public struct CloseIconView: HTMLContent {
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
        .d(M(102.11, 0), l(921.89, 921.89), l(-102.11, 102.11), L(0, 102.83), Z())

      path()
        .d(M(1024, 102.11), L(102.11, 1024), l(-102.11, -102.11), L(921.89, 0), Z())
    }
    .class(stringIsEmpty(`class`) ? "close-icon-view" : "close-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
