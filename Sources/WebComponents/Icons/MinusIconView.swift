import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `minus` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `minus` (ISC;
/// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
/// carried flat into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26). Available on SERVER + CLIENT (the client builds form rows and
/// filter rows with it).
public struct MinusIconView: HTMLContent {
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
      path().d("M46.55 46.55L977.45 46.55")
    }
    .class(stringIsEmpty(`class`) ? "minus-icon-view" : "minus-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 93.09)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.none)
    .stroke(.currentColor)
    .strokeWidth(93.09)
    .strokeLinecap(.round)
    .strokeLinejoin(.round)
    .ariaHidden(true)
    .build()
  }
}

extension IconView {
  /// The subtract icon as a large button wears it before its 18px words
  /// (a form's "+ Genre", "− Testament"): the text's own size (user,
  /// 2026-10-10).
  public static var subtract: IconView {
    IconView(icon: { size in MinusIconView(size: size) }, size: ButtonView.ButtonSize.large.labelIconSize)
  }

  /// The subtract icon alone in a large icon-only button (a filter bar's
  /// bare −): the button's own icon size, 18.
  public static var subtractAlone: IconView {
    IconView(icon: { size in MinusIconView(size: size) }, size: ButtonView.ButtonSize.large.iconSize)
  }
}
