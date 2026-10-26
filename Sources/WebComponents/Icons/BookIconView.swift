#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `book` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `book` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct BookIconView: HTMLContent {
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
        path().d("M46.55 861.09L46.55 162.91A116.36 116.36 0 0 1 162.91 46.55L744.73 46.55A46.55 46.55 0 0 1 791.27 93.09L791.27 930.91A46.55 46.55 0 0 1 744.73 977.45L162.91 977.45A46.54 46.54 0 0 1 162.91 744.73L791.27 744.73")
      }
      .class(stringIsEmpty(`class`) ? "book-icon-view" : "book-icon-view \(`class`)")
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
