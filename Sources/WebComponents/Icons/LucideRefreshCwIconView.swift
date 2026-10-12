#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `refresh-cw` (ISC; THIRD_PARTY_NOTICES.md), for sync. TRIAL
  /// port (user, 2026-10-12): Lucide's 24 geometry (3–21 both ways) scaled
  /// ×896/18 onto the house grid, a 128/1024 stroke with Lucide's round
  /// caps and joins, its outer edges tight to the box.
  public struct LucideRefreshCwIconView: HTMLContent {
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
          .d(
            M(64, 512), a(448, 448, 0, false, true, 448, -448),
            a(485.33, 485.33, 0, false, true, 335.5, 136.39), L(960, 312.89))
        path()
          .d(M(960, 64), v(248.89), h(-248.89))
        path()
          .d(
            M(960, 512), a(448, 448, 0, false, true, -448, 448),
            a(485.33, 485.33, 0, false, true, -335.5, -136.39), L(64, 711.11))
        path()
          .d(M(312.89, 711.11), H(64), v(248.89))
      }
      .class(`class`.isEmpty ? "lucide-refresh-cw-icon-view" : "lucide-refresh-cw-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
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
