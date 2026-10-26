#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `log-out` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `log-out` (ISC;
  /// THIRD_PARTY_NOTICES.md), for signing out. Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct LogOutIconView: HTMLContent {
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
        path().d("M718.87 770.59L977.45 512L718.87 253.41")
        path().d("M977.45 512L356.85 512")
        path().d("M356.85 977.45L149.98 977.45A103.43 103.43 0 0 1 46.55 874.02L46.55 149.98A103.43 103.43 0 0 1 149.98 46.55L356.85 46.55")
      }
      .class(stringIsEmpty(`class`) ? "log-out-icon-view" : "log-out-icon-view \(`class`)")
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
