#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `key` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `key` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct KeyIconView: HTMLContent {
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
        path().d("M46.55 949.61L502.83 493.32")
        path().d("M307.96 688.2L417.28 797.51A47.53 47.53 0 0 1 417.28 864.06L317.46 963.87A47.53 47.53 0 0 1 250.92 963.87L141.6 854.55")
        circle().cx(688.2).cy(307.96).r(261.41)
      }
      .class(stringIsEmpty(`class`) ? "key-icon-view" : "key-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 996.15, 1024)
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
