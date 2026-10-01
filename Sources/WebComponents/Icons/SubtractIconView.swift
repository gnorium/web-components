import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Codex `subtract` icon: the − of a control that subtracts an item from a
/// list ("− Genre", a filter bar's later rows), edge to edge in its 1024-unit box. Available on SERVER +
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
        .d(M(0, 426.67), h(1024), v(170.66), H(0), Z())
    }
    .class(stringIsEmpty(`class`) ? "subtract-icon-view" : "subtract-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}

extension IconView {
  /// The subtract icon as a medium button wears it before its words, or alone
  /// in a compact bar: the size of the button's text (`sizeIconSmall`, as
  /// ButtonView sizes a medium button's icon), so "+ Add genre" reads like
  /// its words.
  public static var subtract: IconView {
    IconView(icon: { size in SubtractIconView(width: size, height: size) }, size: .xSmall)
  }
}
