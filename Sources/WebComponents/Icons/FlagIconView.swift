#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `flag` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `flag` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct FlagIconView: HTMLContent {
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
        path().d("M46.55 977.45L46.55 139.64A46.55 46.55 0 0 1 65.16 102.4A279.27 279.27 0 0 1 232.73 46.55C372.36 46.55 465.45 139.64 574.05 139.64Q667.14 139.64 716.8 102.4A46.55 46.55 0 0 1 791.27 139.64L791.27 605.09A46.55 46.55 0 0 1 772.65 642.33A279.27 279.27 0 0 1 605.09 698.18C465.45 698.18 372.36 605.09 232.73 605.09A279.27 279.27 0 0 0 46.55 676.21")
      }
      .class(stringIsEmpty(`class`) ? "flag-icon-view" : "flag-icon-view \(`class`)")
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
