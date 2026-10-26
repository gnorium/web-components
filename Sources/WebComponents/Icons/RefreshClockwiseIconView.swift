#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `refresh-cw` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `refresh-cw`
  /// (ISC; THIRD_PARTY_NOTICES.md), for sync. Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct RefreshClockwiseIconView: HTMLContent {
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
        path().d("M46.55 512A465.45 465.45 0 0 1 512 46.55A504.24 504.24 0 0 1 860.57 188.25L977.45 305.13")
        path().d("M977.45 46.55L977.45 305.13L718.87 305.13")
        path().d("M977.45 512A465.45 465.45 0 0 1 512 977.45A504.24 504.24 0 0 1 163.43 835.75L46.55 718.87")
        path().d("M305.13 718.87L46.55 718.87L46.55 977.45")
      }
      .class(stringIsEmpty(`class`) ? "refresh-clockwise-icon-view" : "refresh-clockwise-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
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
