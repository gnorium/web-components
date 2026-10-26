import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `layout-list` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `layout-list`
/// (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
/// carried flat into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26).
public struct LayoutListIconView: HTMLContent {
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
      rect().x(46.55).y(46.55).width(362.02).height(362.02).rx(51.72)
      rect().x(46.55).y(615.43).width(362.02).height(362.02).rx(51.72)
      path().d("M615.43 98.26L977.45 98.26")
      path().d("M615.43 356.85L977.45 356.85")
      path().d("M615.43 667.15L977.45 667.15")
      path().d("M615.43 925.74L977.45 925.74")
    }
    .class(stringIsEmpty(`class`) ? "layout-list-icon-view" : "layout-list-icon-view \(`class`)")
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
