#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `sun` (ISC; THIRD_PARTY_NOTICES.md), for the light color scheme. Lucide's
  /// own 24-grid geometry, fitted to the house box by IconStrokeFit: the
  /// long edge 1024, `iconStrokeWidth` thick, round caps and joins, the
  /// outer edges tight to the box (user, 2026-10-12).
  public struct SunIconView: HTMLContent {
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
          circle().cx(12).cy(12).r(4)
          path().d("M12 2v2")
          path().d("M12 20v2")
          path().d("m4.93 4.93 1.41 1.41")
          path().d("m17.66 17.66 1.41 1.41")
          path().d("M2 12h2")
          path().d("M20 12h2")
          path().d("m6.34 17.66-1.41 1.41")
          path().d("m19.07 4.93-1.41 1.41")
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "sun-icon-view" : "sun-icon-view \(`class`)")
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
