#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `chevron-first` (ISC; THIRD_PARTY_NOTICES.md): Lucide's
  /// `chevron-first` (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct ChevronFirstIconView: HTMLContent {
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
        path().d("M822.3 977.45L356.85 512L822.3 46.55")
        path().d("M46.55 46.55L46.55 977.45")
      }
      .class(stringIsEmpty(`class`) ? "chevron-first-icon-view" : "chevron-first-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 868.85, 1024)
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
