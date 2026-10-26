#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `bookmark` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `bookmark`
  /// (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static
  /// 1.60.0), carried flat into the house box: the long edge 1024, the house
  /// stroke (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct BookmarkIconView: HTMLContent {
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
        path().d("M667.16 46.55A103.44 103.44 0 0 1 770.6 149.98L770.6 925.75A51.72 51.72 0 0 1 693.23 970.64L459.88 837.32A103.44 103.44 0 0 0 357.27 837.32L123.92 970.64A51.72 51.72 0 0 1 46.55 925.75L46.55 149.98A103.44 103.44 0 0 1 149.98 46.55Z")
      }
      .class(stringIsEmpty(`class`) ? "bookmark-icon-view" : "bookmark-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 817.14, 1024)
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
