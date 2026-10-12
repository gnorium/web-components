#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `face-slightly-smiling-plus` (ISC; THIRD_PARTY_NOTICES.md), formerly
  /// `smile-plus`, for adding a reaction. Lucide's
  /// own 24-grid geometry, fitted to the house box by IconStrokeFit: the
  /// long edge 1024, `iconStrokeWidth` thick, round caps and joins, the
  /// outer edges tight to the box (user, 2026-10-12).
  public struct FaceSlightlySmilingPlusIconView: HTMLContent {
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
          path().d("M13.267 2.08a10 10 0 1 0 8.653 8.653")
          path().d("M15 10V9")
          path().d("M16 5h6")
          path().d("M16.472 15a6 6 0 0 1-8.943 0")
          path().d("M19 2v6")
          path().d("M9 10V9")
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "face-slightly-smiling-plus-icon-view" : "face-slightly-smiling-plus-icon-view \(`class`)")
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
