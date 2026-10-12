#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `refresh-cw` (ISC; THIRD_PARTY_NOTICES.md), for sync. Lucide's
  /// own 24-grid geometry, fitted to the house box by IconStrokeFit: the
  /// long edge 1024, `iconStrokeWidth` thick, round caps and joins, the
  /// outer edges tight to the box (user, 2026-10-12).
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
      let fit = IconStrokeFit(minX: 3, minY: 3, maxX: 21, maxY: 21)
      return svg {
        g {
          path().d(M(3, 12), a(9, 9, 0, false, true, 9, -9), a(9.75, 9.75, 0, false, true, 6.74, 2.74), L(21, 8))
          path().d(M(21, 3), v(5), h(-5))
          path().d(M(21, 12), a(9, 9, 0, false, true, -9, 9), a(9.75, 9.75, 0, false, true, -6.74, -2.74), L(3, 16))
          path().d(M(8, 16), H(3), v(5))
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "lucide-refresh-cw-icon-view" : "lucide-refresh-cw-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, fit.width, fit.height)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .ariaHidden(true)
      .build()
    }
  }
#endif
