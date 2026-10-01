#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct FacebookIconView: HTMLContent {
    let `class`: String
    let iconSize: CSS.Length
    let fill: CSS.Color
    let monochrome: Bool

    public init(
      class: String = "",
      size: CSS.Length,
      fill: CSS.Color = colorBase,
      monochrome: Bool = false
    ) {
      self.class = `class`
      self.iconSize = size
      self.fill = fill
      self.monochrome = monochrome
    }

    public func build() -> DOM.Node {
      svg {
        defs {
          clipPath {
            path()
              .d(M(-204.8, -204.8), H(1228.8), V(1228.8), H(-204.8), Z())
          }
          .id("facebook-clip")
        }

        g {
          g {
            g {
              // Circle background
              path()
                .d(
                  M(1024, 512), c(0, -282.77, -229.23, -512, -512, -512),
                  c(-282.77, 0, -512, 229.23, -512, 512),
                  c(0, 240.12, 165.3, 441.59, 388.31, 496.92), v(-340.46), h(-105.58), V(512),
                  h(105.58), v(-67.42), c(0, -174.27, 78.87, -255.04, 249.96, -255.04),
                  c(32.43, 0, 88.4, 6.36, 111.3, 12.72), V(344.09),
                  c(-12.09, -1.27, -33.07, -1.91, -59.15, -1.91),
                  c(-83.95, 0, -116.39, 31.8, -116.39, 114.49), V(512), h(167.23),
                  l(-28.72, 156.46), h(-138.51), V(1020.25),
                  C(827.54, 989.63, 1024, 773.77, 1024, 512))
                .fill(monochrome ? fill : hex(0x0866FF))

              // 'f' letter
              path()
                .d(
                  M(712.53, 668.46), L(741.27, 512), H(574.03), v(-55.33),
                  c(0, -82.69, 32.43, -114.49, 116.39, -114.49),
                  c(26.08, 0, 47.06, 0.64, 59.15, 1.91), v(-141.83),
                  c(-22.9, -6.36, -78.87, -12.72, -111.3, -12.72),
                  c(-171.09, 0, -249.96, 80.77, -249.96, 255.04), V(512), h(-105.58), V(668.46),
                  h(105.58), v(340.46), c(39.62, 9.83, 81.04, 15.08, 123.69, 15.08),
                  c(21, 0, 41.69, -1.29, 62.03, -3.75), L(574.03, 668.46), Z())
                .fill(monochrome ? colorInverted : .white)
            }
            .clipPath(url("#facebook-clip"))
          }
        }
      }
      .class(`class`.isEmpty ? "facebook-icon-view" : "facebook-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .xmlnsXlink("http://www.w3.org/1999/xlink")

    }
  }
#endif
