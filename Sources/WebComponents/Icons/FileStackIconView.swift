#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `file-stack` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `file-stack`
  /// (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static
  /// 1.60.0), carried flat into the house box: the long edge 1024, the house
  /// stroke (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct FileStackIconView: HTMLContent {
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
        path().d("M418.91 930.91A46.55 46.55 0 0 1 372.36 977.45L93.09 977.45A46.55 46.55 0 0 1 46.55 930.91L46.55 558.55A46.55 46.55 0 0 1 93.09 512")
        path().d("M651.64 698.18A46.55 46.55 0 0 1 605.09 744.73L325.82 744.73A46.55 46.55 0 0 1 279.27 698.18L279.27 325.82A46.55 46.55 0 0 1 325.82 279.27")
        path().d("M884.36 232.73A93.09 93.09 0 0 0 857.09 166.91L764 73.82A93.09 93.09 0 0 0 698.18 46.55L558.55 46.55A46.55 46.55 0 0 0 512 93.09L512 465.45A46.55 46.55 0 0 0 558.55 512L837.82 512A46.55 46.55 0 0 0 884.36 465.45Z")
      }
      .class(stringIsEmpty(`class`) ? "file-stack-icon-view" : "file-stack-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 930.91, 1024)
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
