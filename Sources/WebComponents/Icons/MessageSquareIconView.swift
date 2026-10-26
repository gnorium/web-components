#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `message-square` (ISC; THIRD_PARTY_NOTICES.md): Lucide's
  /// `message-square` (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct MessageSquareIconView: HTMLContent {
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
        path().d("M977.45 698.18A93.09 93.09 0 0 1 884.36 791.27L271.27 791.27A93.09 93.09 0 0 0 205.45 818.55L102.96 921.04A33.05 33.05 0 0 1 46.55 897.68L46.55 139.64A93.09 93.09 0 0 1 139.64 46.55L884.36 46.55A93.09 93.09 0 0 1 977.45 139.64Z")
      }
      .class(stringIsEmpty(`class`) ? "message-square-icon-view" : "message-square-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 977.26)
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
