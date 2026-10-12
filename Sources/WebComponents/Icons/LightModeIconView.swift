#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct LightModeIconView: HTMLContent {
    let `class`: String
    let iconSize: CSS.Length
    let stroke: CSS.Color

    public init(
      class: String = "",
      size: CSS.Length,
      stroke: CSS.Color = .currentColor
    ) {
      self.class = `class`
      self.iconSize = size
      self.stroke = stroke
    }

    public func build() -> DOM.Node {
      let fit = IconStrokeFit(minX: 50.27, minY: 50.27, maxX: 973.73, maxY: 973.73)
      return svg {
        g {
          path()
            .d(M(511.99, 50.27), V(109.85))
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(838.48, 185.5), L(796.37, 227.62))
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(973.73, 511.99), H(914.15))
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(838.48, 838.48), L(796.37, 796.37))
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(511.99, 973.73), V(914.15))
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(185.5, 838.48), L(227.62, 796.37))
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(50.27, 511.99), H(109.85))
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(185.5, 185.5), L(227.62, 227.62))
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(
              M(512.02, 765.23), C(651.86, 765.23, 765.23, 651.86, 765.23, 512.02),
              C(765.23, 372.18, 651.86, 258.81, 512.02, 258.81),
              C(372.18, 258.81, 258.81, 372.18, 258.81, 512.02),
              C(258.81, 651.86, 372.18, 765.23, 512.02, 765.23), Z())
            .strokeLinecap(.round)
            .strokeLinejoin(.round)
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "light-mode-icon-view" : "light-mode-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, fit.width, fit.height)
      .fill(.none)
      .stroke(stroke)
      .xmlns("http://www.w3.org/2000/svg")

    }
  }
#endif
