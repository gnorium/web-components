import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// The Markdown mark (`M↓` in a rounded rectangle) by Dustin Curtis
/// (dcurtis/markdown-mark, CC0; credited in THIRD_PARTY_NOTICES.md), the Raw
/// switch of a Markdown source (user, 2026-10-12). Carried flat into the house
/// box: the long edge 1024, the house stroke (`iconStrokeWidth`), round caps
/// and joins, tight to the box (user, 2026-10-26). SERVER + CLIENT: a streamed
/// or replayed continuation prompt carries it too, so its paths are written out
/// (no number formatting on the client).
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
    svg {
      path().d("M112.37 46.55L911.63 46.55A65.82 65.82 0 0 1 977.45 112.37L977.45 535.51A65.82 65.82 0 0 1 911.63 601.33L112.37 601.33A65.82 65.82 0 0 1 46.55 535.51L46.55 112.37A65.82 65.82 0 0 1 112.37 46.55Z")
      path().d("M211.1 441.48L211.1 206.4L352.15 349.8L493.19 206.4L493.19 441.48")
      path().d("M751.78 206.4L751.78 441.48M638.94 328.64L751.78 441.48L864.62 328.64")
    }
    .class(stringIsEmpty(`class`) ? "markdown-icon-view" : "markdown-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 647.88)
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
