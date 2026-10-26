import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `plus` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `plus` (ISC;
/// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
/// carried flat into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26). Available on SERVER + CLIENT (the client builds form rows and
/// filter rows with it).
public struct PlusIconView: HTMLContent {
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
      path().d("M46.55 512L977.45 512")
      path().d("M512 46.55L512 977.45")
    }
    .class(stringIsEmpty(`class`) ? "plus-icon-view" : "plus-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 1024, 1024)
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
  /// The add icon as a large button wears it before its 18px words
  /// (a form's "+ Genre", "− Testament"): the text's own size (user,
  /// 2026-10-10).
  public static var add: IconView {
    IconView(icon: { size in PlusIconView(size: size) }, size: ButtonView.ButtonSize.large.labelIconSize)
  }

  /// The add icon alone in a large icon-only button (a filter bar's
  /// bare +): the button's own icon size, 18.
  public static var addAlone: IconView {
    IconView(icon: { size in PlusIconView(size: size) }, size: ButtonView.ButtonSize.large.iconSize)
  }
}
