#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `merge` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `merge` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct MergeIconView: HTMLContent {
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
        path().d("M232.73 232.73L418.91 46.55L605.09 232.73")
        path().d("M418.91 46.55L418.91 525.96A186.18 186.18 0 0 1 364.36 659.64L46.55 977.45")
        path().d("M791.27 977.45L558.55 744.73")
      }
      .class(stringIsEmpty(`class`) ? "merge-icon-view" : "merge-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 837.82, 1024)
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
