import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Codex `add` icon: the + of a control that adds or creates ("+ Genre",
/// a filter bar's first row), drawn edge to edge in its 12-unit box so it
/// sits tight to its label. Available on SERVER + CLIENT (the client
/// builds form rows and filter rows with it).
public struct AddIconView: HTMLContent {
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
        .d(M(7, 5), V(0), H(5), v(5), H(0), v(2), h(5), v(5), h(2), v(-5), h(5), V(5), Z())
    }
    .class(stringIsEmpty(`class`) ? "add-icon-view" : "add-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 12, 12)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}

extension IconView {
  /// The add icon as a medium button wears it before its words, or alone
  /// in a compact bar: the size of the button's text (`sizeIconSmall`, as
  /// ButtonView sizes a medium button's icon), so "+ Add genre" reads like
  /// its words.
  public static var add: IconView {
    IconView(icon: { size in AddIconView(width: size, height: size) }, size: .xSmall)
  }
}
