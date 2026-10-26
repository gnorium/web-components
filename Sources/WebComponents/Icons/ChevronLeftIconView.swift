import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import HTMLBuilder
import SVGBuilder
import WebTypes
import EmbeddedSwiftUtilities

/// Lucide's `chevron-left` (ISC; THIRD_PARTY_NOTICES.md): Lucide's
/// `chevron-left` (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry
/// (lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26).
public struct ChevronLeftIconView: HTMLContent {
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
      path().d("M512 977.45L46.55 512L512 46.55")
    }
    .class(stringIsEmpty(`class`) ? "chevron-left-icon-view" : "chevron-left-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 558.55, 1024)
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
