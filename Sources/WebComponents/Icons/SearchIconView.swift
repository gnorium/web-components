import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `search` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `search` (ISC;
/// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
/// carried flat into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26).
public struct SearchIconView: HTMLContent {
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
      path().d("M977.45 977.45L753 753")
      circle().cx(460.28).cy(460.28).r(413.74)
    }
    .class(stringIsEmpty(`class`) ? "search-icon-view" : "search-icon-view \(`class`)")
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
