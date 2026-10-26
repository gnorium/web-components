#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `grip-vertical` (ISC; THIRD_PARTY_NOTICES.md): Lucide's
  /// `grip-vertical` (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct GripVerticalIconView: HTMLContent {
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
        circle().cx(104.73).cy(512).r(58.18)
        circle().cx(104.73).cy(104.73).r(58.18)
        circle().cx(104.73).cy(919.27).r(58.18)
        circle().cx(453.82).cy(512).r(58.18)
        circle().cx(453.82).cy(104.73).r(58.18)
        circle().cx(453.82).cy(919.27).r(58.18)
      }
      .class(stringIsEmpty(`class`) ? "grip-vertical-icon-view" : "grip-vertical-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 558.55, 1024)
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
