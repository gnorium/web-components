#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `link` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `link` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct LinkIconView: HTMLContent {
    let iconSize: CSS.Length
    let `class`: String

    public init(size: CSS.Length, class: String = "") {
      self.iconSize = size
      self.class = `class`
    }

    public func build() -> DOM.Node {
      svg {
        path().d("M418.38 558.34A234.05 234.05 0 0 0 771.33 583.62L911.75 443.19A234.05 234.05 0 0 0 580.81 112.25L500.3 192.29")
        path().d("M605.62 464.72A234.05 234.05 0 0 0 252.67 439.45L112.25 579.87A234.05 234.05 0 0 0 443.19 910.82L523.23 830.77")
      }
      .class(stringIsEmpty(`class`) ? "link-icon-view" : "link-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 1023.06)
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
