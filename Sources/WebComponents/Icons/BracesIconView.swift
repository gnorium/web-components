import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `braces` (`{}`) (ISC; THIRD_PARTY_NOTICES.md), the JSON switch
/// of a tool call. Lucide's own 24-grid geometry, fitted to the house box
/// by IconStrokeFit: the long edge 1024, `iconStrokeWidth` thick, round
/// caps and joins, the outer edges tight to the box (user, 2026-10-12).
/// SERVER + CLIENT: a streamed or replayed tool card carries it too.
public struct BracesIconView: HTMLContent {
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
    let fit = IconStrokeFit(minX: 3, minY: 3, maxX: 21, maxY: 21)
    return svg {
      g {
        path().d("M8 3H7a2 2 0 0 0-2 2v5a2 2 0 0 1-2 2 2 2 0 0 1 2 2v5c0 1.1.9 2 2 2h1")
        path().d("M16 21h1a2 2 0 0 0 2-2v-5c0-1.1.9-2 2-2a2 2 0 0 1-2-2V5a2 2 0 0 0-2-2h-1")
      }
      .transform(fit.transform)
      .strokeWidth(fit.strokeWidth)
    }
    .class(stringIsEmpty(`class`) ? "braces-icon-view" : "braces-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, fit.width, fit.height)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.none)
    .stroke(.currentColor)
    .strokeLinecap(.round)
    .strokeLinejoin(.round)
    .ariaHidden(true)
    .build()
  }
}
