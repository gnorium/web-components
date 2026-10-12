#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `text-wrap` (`wrap-text` before Lucide renamed it; ISC,
  /// THIRD_PARTY_NOTICES.md), for Reflow. TRIAL port (user, 2026-10-12):
  /// Lucide's 24 geometry (x 3–21, y 5–22) scaled ×896/18 onto the house
  /// grid, a 128/1024 stroke with Lucide's round caps and joins, its outer
  /// edges tight to the box (1024 × 974.22). Lucide writes the turn as
  /// `a1 1 0 0 1 0 7`, a radius the renderer grows to the half chord;
  /// here it is that radius, 3.5, outright.
  public struct LucideTextWrapIconView: HTMLContent {
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
        path()
          .d(M(711.11, 611.56), l(-149.33, 149.33), l(149.33, 149.33))
        path()
          .d(M(64, 412.44), h(721.78), a(174.22, 174.22, 0, false, true, 0, 348.44), H(561.78))
        path()
          .d(M(64, 760.89), h(298.67))
        path()
          .d(M(64, 64), h(896))
      }
      .class(`class`.isEmpty ? "lucide-text-wrap-icon-view" : "lucide-text-wrap-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 974.22)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeWidth(128)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .ariaHidden(true)
      .build()
    }
  }
#endif
