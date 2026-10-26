#if SERVER
  import HTMLBuilder
  import SVGBuilder
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebTypes

  /// Lucide's `heart` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `heart` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct HeartIconView: HTMLContent {
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
        path().d("M46.55 303.3A256 256 0 0 1 492.96 132.2A26.07 26.07 0 0 0 531.04 132.2A255.53 255.53 0 0 1 977.45 303.3C977.45 409.89 907.63 489.48 837.82 559.3L582.19 806.59A93.09 93.09 0 0 1 442.55 807.48L186.18 559.3C116.36 489.48 46.55 410.35 46.55 303.3")
      }
      .class(stringIsEmpty(`class`) ? "heart-icon-view" : "heart-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 885.1)
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
