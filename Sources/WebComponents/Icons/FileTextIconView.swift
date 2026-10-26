  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import EmbeddedSwiftUtilities
  import SVGBuilder
  import WebTypes

  /// Lucide's `file-text` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `file-text`
  /// (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static
  /// 1.60.0), carried flat into the house box: the long edge 1024, the house
  /// stroke (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct FileTextIconView: HTMLContent {
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
        path().d("M139.64 977.45A93.09 93.09 0 0 1 46.55 884.36L46.55 139.64A93.09 93.09 0 0 1 139.64 46.55L512 46.55A111.71 111.71 0 0 1 591.31 79.41L758.32 246.41A111.71 111.71 0 0 1 791.27 325.82L791.27 884.36A93.09 93.09 0 0 1 698.18 977.45Z")
        path().d("M512 46.55L512 279.27A46.55 46.55 0 0 0 558.55 325.82L791.27 325.82")
        path().d("M325.82 372.36L232.73 372.36")
        path().d("M605.09 558.55L232.73 558.55")
        path().d("M605.09 744.73L232.73 744.73")
      }
      .class(stringIsEmpty(`class`) ? "file-text-icon-view" : "file-text-icon-view \(`class`)")
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
