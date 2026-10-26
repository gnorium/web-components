#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `log-in` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `log-in` (ISC;
  /// THIRD_PARTY_NOTICES.md), for signing in. Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct LogInIconView: HTMLContent {
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
        path().d("M408.57 770.59L667.15 512L408.57 253.41")
        path().d("M667.15 512L46.55 512")
        path().d("M667.15 46.55L874.02 46.55A103.43 103.43 0 0 1 977.45 149.98L977.45 874.02A103.43 103.43 0 0 1 874.02 977.45L667.15 977.45")
      }
      .class(stringIsEmpty(`class`) ? "log-in-icon-view" : "log-in-icon-view \(`class`)")
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
