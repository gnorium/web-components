import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `calendar` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `calendar` (ISC;
/// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
/// carried flat into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26).
public struct CalendarIconView: HTMLContent {
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
      path().d("M291.52 46.55L291.52 193.53")
      path().d("M683.48 46.55L683.48 193.53")
      rect().x(46.55).y(95.54).width(881.91).height(881.91).rx(97.99)
      path().d("M46.55 389.51L928.46 389.51")
    }
    .class(stringIsEmpty(`class`) ? "calendar-icon-view" : "calendar-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 975, 1024)
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
