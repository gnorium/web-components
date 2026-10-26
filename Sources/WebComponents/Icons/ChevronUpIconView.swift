import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `chevron-up` (ISC; THIRD_PARTY_NOTICES.md): Collapse / compress
/// glyph. Lucide's own geometry (lucide-static 1.60.0), carried flat into the
/// house box: the long edge 1024, the house stroke (`iconStrokeWidth`), round
/// caps and joins, tight to the box (user, 2026-10-26). Available on SERVER +
/// CLIENT: the live trace builds the compaction card with it, as the server
/// does.
public struct ChevronUpIconView: HTMLContent {
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
      path().d("M977.45 512L512 46.55L46.55 512")
    }
    .class(stringIsEmpty(`class`) ? "chevron-up-icon-view" : "chevron-up-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 558.55)
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
