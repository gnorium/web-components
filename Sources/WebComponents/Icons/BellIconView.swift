import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `bell` (ISC; THIRD_PARTY_NOTICES.md): Notices, what others did
/// that concerns the reader (user, 2026-11-14). Lucide's own geometry carried
/// flat into the house box: the long edge (its height) 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box. SERVER +
/// CLIENT.
public struct BellIconView: HTMLContent {
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
      path().d("M384.81 930.91A93.09 93.09 0 0 0 546.04 930.91")
      path().d(
        "M58.71 666.81A46.55 46.55 0 0 0 93.06 744.73L837.79 744.73A46.55 46.55 0 0 0 872.23 666.86C810.33 603.05 744.7 535.23 744.7 325.82A279.27 279.27 0 0 0 186.15 325.82C186.15 535.23 120.47 603.05 58.71 666.81"
      )
    }
    .class(stringIsEmpty(`class`) ? "bell-icon-view" : "bell-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 930.9, 1024)
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
