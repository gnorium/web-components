#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `refresh-cw-off` (ISC; THIRD_PARTY_NOTICES.md), for detaching. Lucide's
  /// own 24-grid geometry, fitted to the house box by IconStrokeFit: the
  /// long edge 1024, `iconStrokeWidth` thick, round caps and joins, the
  /// outer edges tight to the box (user, 2026-10-12).
  public struct RefreshClockwiseOffIconView: HTMLContent {
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
      let fit = IconStrokeFit(minX: 2, minY: 2, maxX: 22, maxY: 22)
      return svg {
        g {
          path().d(M(21, 8), L(18.74, 5.74), A(9.75, 9.75, 0, false, false, 12, 3), C(11, 3, 10.03, 3.16, 9.13, 3.47))
          path().d(M(8, 16), H(3), v(5))
          path().d(M(3, 12), C(3, 9.51, 4, 7.26, 5.64, 5.64))
          path().d(M(3, 16), l(2.26, 2.26), A(9.75, 9.75, 0, false, false, 12, 21), c(2.49, 0, 4.74, -1, 6.36, -2.64))
          path().d(M(21, 12), c(0, 1, -0.16, 1.97, -0.47, 2.87))
          path().d(M(21, 3), v(5), h(-5))
          path().d(M(22, 22), L(2, 2))
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "refresh-clockwise-off-icon-view" : "refresh-clockwise-off-icon-view \(`class`)")
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
