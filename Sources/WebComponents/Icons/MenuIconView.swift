#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import SVGBuilder
  import HTMLBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebTypes

  /// Lucide's `menu` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `menu` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct MenuIconView: HTMLContent {
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
        path().d("M46.55 46.55L977.45 46.55")
        path().d("M46.55 453.82L977.45 453.82")
        path().d("M46.55 861.09L977.45 861.09")
      }
      .class(stringIsEmpty(`class`) ? "menu-icon-view" : "menu-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 907.64)
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
