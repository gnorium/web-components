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
    let strokeWidth: CSS.Length

    public init(
      class: String = "",
      size: CSS.Length,
      stroke: CSS.Color = .currentColor,
      strokeWidth: CSS.Length = 100.54
    ) {
      self.class = `class`
      self.iconSize = size
      self.stroke = stroke
      self.strokeWidth = strokeWidth
    }

    public func build() -> DOM.Node {
      svg {
        defs {
          clipPath {
            rect().x(-24.22).y(-24.22).width(1072.42).height(1072.42).fill(.white)
          }
          .id("clip")
        }

        g {
          path()
            .d(M(511.99, 50.27), V(109.85))
            .strokeWidth(strokeWidth)
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(838.48, 185.5), L(796.37, 227.62))
            .strokeWidth(strokeWidth)
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(973.73, 511.99), H(914.15))
            .strokeWidth(strokeWidth)
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(838.48, 838.48), L(796.37, 796.37))
            .strokeWidth(strokeWidth)
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(511.99, 973.73), V(914.15))
            .strokeWidth(strokeWidth)
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(185.5, 838.48), L(227.62, 796.37))
            .strokeWidth(strokeWidth)
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(50.27, 511.99), H(109.85))
            .strokeWidth(strokeWidth)
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(M(185.5, 185.5), L(227.62, 227.62))
            .strokeWidth(strokeWidth)
            .strokeLinecap(.round)
            .strokeLinejoin(.round)

          path()
            .d(
              M(512.02, 765.23), C(651.86, 765.23, 765.23, 651.86, 765.23, 512.02),
              C(765.23, 372.18, 651.86, 258.81, 512.02, 258.81),
              C(372.18, 258.81, 258.81, 372.18, 258.81, 512.02),
              C(258.81, 651.86, 372.18, 765.23, 512.02, 765.23), Z())
            .strokeWidth(strokeWidth)
            .strokeLinecap(.round)
            .strokeLinejoin(.round)
        }
        .clipPath(url("#clip"))
      }
      .class(`class`.isEmpty ? "light-mode-icon-view" : "light-mode-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .fill(.none)
      .stroke(stroke)
      .xmlns("http://www.w3.org/2000/svg")

    }
  }
#endif
