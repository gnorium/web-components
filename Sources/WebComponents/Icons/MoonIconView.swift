#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `moon` (ISC; THIRD_PARTY_NOTICES.md), for the dark color scheme. Lucide's
  /// own 24-grid geometry, fitted to the house box by IconStrokeFit: the
  /// long edge 1024, `iconStrokeWidth` thick, round caps and joins, the
  /// outer edges tight to the box (user, 2026-10-12). Its bounds are the
  /// crescent's measured extremes, its horns' rounded tips included.
  public struct MoonIconView: HTMLContent {
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
      let fit = IconStrokeFit(minX: 2.998, minY: 3.013, maxX: 20.986, maxY: 21.001)
      return svg {
        g {
          path().d("M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401")
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "moon-icon-view" : "moon-icon-view \(`class`)")
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
