#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `check-check` (ISC; THIRD_PARTY_NOTICES.md): Lucide's
  /// `check-check` (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct CheckCheckIconView: HTMLContent {
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
        path().d("M791.27 46.55L279.27 558.55L46.55 325.82")
        path().d("M977.45 232.73L628.36 581.82L558.55 512")
      }
      .class(stringIsEmpty(`class`) ? "check-check-icon-view" : "check-check-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 628.36)
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
