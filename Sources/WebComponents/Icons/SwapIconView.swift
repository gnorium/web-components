#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Two opposite arrows, each a shaft with a head of two arms at 45°, the
  /// tails extended so the pair fills a square. Fitted to the house box by
  /// IconStrokeFit: `iconStrokeWidth` thick, round caps and joins, the
  /// outer edges tight to the box.
  public struct SwapIconView: HTMLContent {
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
      let fit = IconStrokeFit(minX: 0, minY: 64, maxX: 1024, maxY: 960)
      return svg {
        g {
          path()
            .d(M(0, 256), H(928), M(736, 64), L(928, 256), L(736, 448))
          path()
            .d(M(1024, 768), H(96), M(288, 576), L(96, 768), L(288, 960))
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "swap-icon-view" : "swap-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, fit.width, fit.height)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
    }
  }
#endif
