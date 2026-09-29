import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Codex `subtract` icon: the − of a control that subtracts an item from a
/// list ("Remove genre", a filter bar's later rows). Available on SERVER +
/// CLIENT (the client builds form rows and filter rows with it).
public struct SubtractIconView: HTMLContent {
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
        .d(M(4, 9), h(12), v(2), H(4), Z())
    }
    .class(stringIsEmpty(`class`) ? "subtract-icon-view" : "subtract-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 20, 20)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
