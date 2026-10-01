import CSSBuilder
import CSSOMBuilder
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
        .d(M(0, 0), h(1024), v(170.67), H(0), Z())
    }
    .class(stringIsEmpty(`class`) ? "subtract-icon-view" : "subtract-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 170.67)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}

extension IconView {
  /// The subtract icon as a medium button wears it before its 16px words:
  /// sizeIconXSmall, the text's size minus 4px, so "− Genre" reads like
  /// its words (IconView.size(beside:)).
  public static var subtract: IconView {
    IconView(icon: { size in SubtractIconView(size: size) }, size: sizeIconXSmall)
  }

  /// The subtract icon alone in a medium icon-only button (a filter bar's
  /// bare −): sizeIconSmall, the button's own icon size.
  public static var subtractAlone: IconView {
    IconView(icon: { size in SubtractIconView(size: size) }, size: sizeIconSmall)
  }
}
