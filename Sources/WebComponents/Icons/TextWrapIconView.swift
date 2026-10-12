#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `text-wrap` (`wrap-text` before
  /// Lucide renamed it) (ISC; THIRD_PARTY_NOTICES.md), for Reflow. Lucide's
  /// own 24-grid geometry, fitted to the house box by IconStrokeFit: the
  /// long edge 1024, `iconStrokeWidth` thick, round caps and joins, the
  /// outer edges tight to the box (user, 2026-10-12).
  /// Lucide writes the turn as `a1 1 0 0 1 0 7`, a radius the renderer
  /// grows to the half chord; here it is that radius, 3.5, outright.
  public struct TextWrapIconView: HTMLContent {
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
      let fit = IconStrokeFit(minX: 3, minY: 5, maxX: 21, maxY: 22)
      return svg {
        g {
          path().d(M(16, 16), l(-3, 3), l(3, 3))
          path().d(M(3, 12), h(14.5), a(3.5, 3.5, 0, false, true, 0, 7), H(13))
          path().d(M(3, 19), h(6))
          path().d(M(3, 5), h(18))
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "text-wrap-icon-view" : "text-wrap-icon-view \(`class`)")
      .style { width(iconSize) }
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
