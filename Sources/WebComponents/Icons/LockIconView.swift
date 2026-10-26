#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `lock` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `lock` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct LockIconView: HTMLContent {
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
        rect().x(46.55).y(465.45).width(837.82).height(512).rx(93.09)
        path().d("M232.73 465.45L232.73 279.27A232.72 232.72 0 0 1 698.18 279.27L698.18 465.45")
      }
      .class(stringIsEmpty(`class`) ? "lock-icon-view" : "lock-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 930.91, 1024)
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
