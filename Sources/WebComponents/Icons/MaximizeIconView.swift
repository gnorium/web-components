#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `maximize` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `maximize`
  /// (ISC; THIRD_PARTY_NOTICES.md), to go full screen. Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct MaximizeIconView: HTMLContent {
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
        path().d("M305.13 46.55L149.98 46.55A103.43 103.43 0 0 0 46.55 149.98L46.55 305.13")
        path().d("M977.45 305.13L977.45 149.98A103.43 103.43 0 0 0 874.02 46.55L718.87 46.55")
        path().d("M46.55 718.87L46.55 874.02A103.43 103.43 0 0 0 149.98 977.45L305.13 977.45")
        path().d("M718.87 977.45L874.02 977.45A103.43 103.43 0 0 0 977.45 874.02L977.45 718.87")
      }
      .class(stringIsEmpty(`class`) ? "maximize-icon-view" : "maximize-icon-view \(`class`)")
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
