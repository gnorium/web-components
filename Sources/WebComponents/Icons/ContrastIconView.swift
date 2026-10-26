#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `contrast` (ISC; THIRD_PARTY_NOTICES.md): a circle and its right
  /// half, outlined for less contrast. Lucide has the one form, so `filled`
  /// makes the pair's other: the half solid, for more contrast. Lucide's own
  /// geometry (lucide-static 1.60.0), carried flat into the house box: the long
  /// edge 1024, the house stroke (`iconStrokeWidth`), round caps and joins,
  /// tight to the box (user, 2026-10-26).
  public struct ContrastIconView: HTMLContent {
    let iconSize: CSS.Length
    let filled: Bool
    let `class`: String

    public init(
      size: CSS.Length,
      filled: Bool = false,
      class: String = ""
    ) {
      self.iconSize = size
      self.filled = filled
      self.class = `class`
    }

    public func build() -> DOM.Node {
      svg {
        circle().cx(512).cy(512).r(465.45)
        path().d("M512 791.27A279.27 279.27 0 0 0 512 232.73L512 791.27Z")
      }
      .class(stringIsEmpty(`class`) ? "contrast-icon-view" : "contrast-icon-view \(`class`)")
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
#endif
