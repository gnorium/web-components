import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `delete` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `delete` (ISC;
/// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
/// carried flat into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26).
public struct DeleteIconView: HTMLContent {
  let `class`: String
  let iconSize: CSS.Length

  public init(
    class: String = "",
    size: CSS.Length
  ) {
    self.class = `class`
    self.iconSize = size
  }

  public func build() -> DOM.Node {
    svg {
      path().d("M418.91 46.55A93.09 93.09 0 0 0 356.35 70.7L61.81 337.87A46.55 46.55 0 0 0 61.81 406.81L356.35 674.03A93.09 93.09 0 0 0 418.91 698.18L884.36 698.18A93.09 93.09 0 0 0 977.45 605.09L977.45 139.64A93.09 93.09 0 0 0 884.36 46.55Z")
      path().d("M512 232.73L791.27 512")
      path().d("M791.27 232.73L512 512")
    }
    .class(stringIsEmpty(`class`) ? "delete-icon-view" : "delete-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 744.73)
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
