#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `contrast` (ISC; THIRD_PARTY_NOTICES.md): a circle and its
  /// right half, outlined for less contrast. Lucide has the one form, so
  /// `filled` makes the pair's other: the half solid, for more contrast.
  /// Lucide's own 24-grid geometry, fitted to the house box by
  /// IconStrokeFit: the long edge 1024, `iconStrokeWidth` thick, round caps
  /// and joins, the outer edges tight to the box (user, 2026-10-12).
  public struct ContrastIconView: HTMLContent {
    let iconSize: CSS.Length
    let filled: Bool
    let `class`: String

    public init(
      size: CSS.Length,
      filled: Bool = false,
      class: String = ""
    ) {
      self.iconSize = size
      self.filled = filled
      self.class = `class`
    }

    public func build() -> DOM.Node {
      let fit = IconStrokeFit(minX: 2, minY: 2, maxX: 22, maxY: 22)
      return svg {
        g {
          circle().cx(12).cy(12).r(10)
          if filled {
            path().d("M12 18a6 6 0 0 0 0-12v12z").fill(.currentColor)
          } else {
            path().d("M12 18a6 6 0 0 0 0-12v12z")
          }
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "contrast-icon-view" : "contrast-icon-view \(`class`)")
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
