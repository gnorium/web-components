import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Codex `add` icon: the + of a control that adds or creates ("Add genre",
/// a filter bar's first row). Available on SERVER + CLIENT (the client
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
        .d(M(11, 9), V(4), H(9), v(5), H(4), v(2), h(5), v(5), h(2), v(-5), h(5), V(9), Z())
    }
    .class(stringIsEmpty(`class`) ? "add-icon-view" : "add-icon-view \(`class`)")
    .width(width)
    .height(height)
    .viewBox(0, 0, 20, 20)
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
    IconView(icon: { size in AddIconView(width: size, height: size) }, size: .small)
  }
}
