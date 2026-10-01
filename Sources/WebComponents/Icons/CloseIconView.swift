import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Codex `close` icon: the ✕ of a close or dismiss button. Available on
/// SERVER + CLIENT (client code renders it: `StatusIconView` shows how).
public struct CloseIconView: HTMLContent {
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
        .d(M(102.11, 0), l(921.89, 921.89), l(-102.11, 102.11), L(0, 102.83), Z())

      path()
        .d(M(1024, 102.11), L(102.11, 1024), l(-102.11, -102.11), L(921.89, 0), Z())
    }
    .class(stringIsEmpty(`class`) ? "close-icon-view" : "close-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
