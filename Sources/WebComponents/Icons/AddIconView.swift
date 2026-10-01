import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Codex `add` icon: the + of a control that adds or creates ("+ Genre",
/// a filter bar's first row), drawn edge to edge in its 1024-unit box so it
/// sits tight to its label. Available on SERVER + CLIENT (the client
/// builds form rows and filter rows with it).
public struct AddIconView: HTMLContent {
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
          M(597.33, 426.67), V(0), H(426.67), v(426.67), H(0), v(170.66), h(426.67), v(426.67),
          h(170.66), v(-426.67), h(426.67), V(426.67), Z())
    }
    .class(stringIsEmpty(`class`) ? "add-icon-view" : "add-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}

extension IconView {
  /// The add icon as a medium button wears it before its 16px words:
  /// sizeIconXSmall, the text's size minus 4px, so "+ Genre" reads like
  /// its words (IconView.size(beside:)).
  public static var add: IconView {
    IconView(icon: { size in AddIconView(size: size) }, size: sizeIconXSmall)
  }

  /// The add icon alone in a medium icon-only button (a filter bar's
  /// bare +): sizeIconSmall, the button's own icon size.
  public static var addAlone: IconView {
    IconView(icon: { size in AddIconView(size: size) }, size: sizeIconSmall)
  }
}
