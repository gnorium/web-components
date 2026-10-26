#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `forward` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `forward` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct ForwardIconView: HTMLContent {
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
        path().d("M686.55 628.36L977.45 337.45L686.55 46.55")
        path().d("M46.55 686.55L46.55 570.18A232.73 232.73 0 0 1 279.27 337.45L977.45 337.45")
      }
      .class(stringIsEmpty(`class`) ? "forward-icon-view" : "forward-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 733.09)
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
