import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `braces` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `braces` (`{}`)
/// (ISC; THIRD_PARTY_NOTICES.md), the JSON switch of a tool call. Lucide's own
/// geometry (lucide-static 1.60.0), carried flat into the house box: the long
/// edge 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight
/// to the box (user, 2026-10-26). SERVER + CLIENT: a streamed or replayed tool
/// card carries it too.
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
    svg {
      path().d("M305.13 46.55L253.41 46.55A103.43 103.43 0 0 0 149.98 149.98L149.98 408.57A103.43 103.43 0 0 1 46.55 512A103.43 103.43 0 0 1 149.98 615.43L149.98 874.02C149.98 930.91 196.53 977.45 253.41 977.45L305.13 977.45")
      path().d("M718.87 977.45L770.59 977.45A103.43 103.43 0 0 0 874.02 874.02L874.02 615.43C874.02 558.55 920.57 512 977.45 512A103.43 103.43 0 0 1 874.02 408.57L874.02 149.98A103.43 103.43 0 0 0 770.59 46.55L718.87 46.55")
    }
    .class(stringIsEmpty(`class`) ? "braces-icon-view" : "braces-icon-view \(`class`)")
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
