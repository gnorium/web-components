#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `list` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `list` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct ListIconView: HTMLContent {
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
        path().d("M46.55 46.55L47.06 46.55")
        path().d("M46.55 408.57L47.06 408.57")
        path().d("M46.55 770.59L47.06 770.59")
        path().d("M305.13 46.55L977.45 46.55")
        path().d("M305.13 408.57L977.45 408.57")
        path().d("M305.13 770.59L977.45 770.59")
      }
      .class(stringIsEmpty(`class`) ? "list-icon-view" : "list-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 817.13)
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
