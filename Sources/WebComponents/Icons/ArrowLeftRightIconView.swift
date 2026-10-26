#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `arrow-left-right` (ISC; THIRD_PARTY_NOTICES.md): Two opposite
  /// arrows, each a shaft with a head of two arms at 45°, the tails extended so
  /// the pair fills a square. Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct ArrowLeftRightIconView: HTMLContent {
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
        path().d("M253.41 46.55L46.55 253.41L253.41 460.28")
        path().d("M46.55 253.41L874.02 253.41")
        path().d("M667.15 977.45L874.02 770.59L667.15 563.72")
        path().d("M874.02 770.59L46.55 770.59")
      }
      .class(stringIsEmpty(`class`) ? "arrow-left-right-icon-view" : "arrow-left-right-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 920.57, 1024)
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
