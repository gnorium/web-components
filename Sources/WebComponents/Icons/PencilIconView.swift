#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `pencil` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `pencil` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct PencilIconView: HTMLContent {
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
        path().d("M939.01 270.54A46.54 46.54 0 0 0 753.48 84.96L132.28 706.3A93.09 93.09 0 0 0 109.01 744.94L47.52 947.51A23.27 23.27 0 0 0 76.52 976.46L279.13 915.02A93.09 93.09 0 0 0 317.77 891.88Z")
        path().d("M651.64 186.2L837.82 372.38")
      }
      .class(stringIsEmpty(`class`) ? "pencil-icon-view" : "pencil-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 1023.99)
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
