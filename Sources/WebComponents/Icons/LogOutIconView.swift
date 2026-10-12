#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `log-out` (ISC; THIRD_PARTY_NOTICES.md), for signing out. Lucide's
  /// own 24-grid geometry, fitted to the house box by IconStrokeFit: the
  /// long edge 1024, `iconStrokeWidth` thick, round caps and joins, the
  /// outer edges tight to the box (user, 2026-10-12).
  public struct LogOutIconView: HTMLContent {
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
          path().d("m16 17 5-5-5-5")
          path().d("M21 12H9")
          path().d("M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4")
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "log-out-icon-view" : "log-out-icon-view \(`class`)")
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
