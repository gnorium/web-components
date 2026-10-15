import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// The Markdown mark (`M↓` in a rounded rectangle) by Dustin Curtis
/// (dcurtis/markdown-mark, CC0; credited in THIRD_PARTY_NOTICES.md), the
/// Raw switch of a Markdown source (user, 2026-10-12). Its outline
/// variant redrawn in strokes on the mark's own 208 × 128 grid: the
/// frame's centerline 5–203 × 5–123 with corners of radius 14, the
/// filled M and arrow of the original as strokes along their middles
/// (the M's legs at 40 and 100, its V down to 69.5; the arrow's shaft at
/// 155, its head 24 wide on each side, its tip at 89). Fitted to the
/// house box by IconStrokeFit: the long edge 1024, `iconStrokeWidth`
/// thick, round caps and joins, the frame's outer edges tight to the box.
/// SERVER + CLIENT: a streamed or replayed continuation prompt carries it
/// too, so its paths are written out (no number formatting on the client).
public struct MarkdownIconView: HTMLContent {
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
    let fit = IconStrokeFit(minX: 5, minY: 5, maxX: 203, maxY: 123)
    return svg {
      g {
        path().d("M19 5H189A14 14 0 0 1 203 19V109A14 14 0 0 1 189 123H19A14 14 0 0 1 5 109V19A14 14 0 0 1 19 5Z")
        path().d("M40 89V39L70 69.5L100 39V89")
        path().d("M155 39V89M131 65L155 89L179 65")
      }
      .transform(fit.transform)
      .strokeWidth(fit.strokeWidth)
    }
    .class(stringIsEmpty(`class`) ? "markdown-icon-view" : "markdown-icon-view \(`class`)")
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
