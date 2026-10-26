#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import SVGBuilder
  import HTMLBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebTypes

  /// Lucide's `chevron-last` (ISC; THIRD_PARTY_NOTICES.md): Lucide's
  /// `chevron-last` (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct ChevronLastIconView: HTMLContent {
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
        path().d("M46.55 977.45L512 512L46.55 46.55")
        path().d("M822.3 46.55L822.3 977.45")
      }
      .class(stringIsEmpty(`class`) ? "chevron-last-icon-view" : "chevron-last-icon-view \(`class`)")
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
