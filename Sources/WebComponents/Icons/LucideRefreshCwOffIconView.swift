#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `refresh-cw-off` (ISC; THIRD_PARTY_NOTICES.md), for detach.
  /// TRIAL port (user, 2026-10-12): Lucide's 24 geometry (2–22 both ways,
  /// the slash reaching past the arrows) scaled ×44.8 onto the house grid,
  /// a 128/1024 stroke with Lucide's round caps and joins, its outer edges
  /// tight to the box.
  ///
  /// Hover (its host button's, or keyboard focus): the icon shakes side to
  /// side twice and settles, once, as the animated Lucide set's
  /// refresh-cw-off does (pqoqubbw/icons, MIT; there 3px of a 28px icon,
  /// here a subtler 6% of its width).
  public struct LucideRefreshCwOffIconView: HTMLContent {
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
      svg {
        path()
          .d(
            M(915.2, 332.8), L(813.95, 231.55), A(436.8, 436.8, 0, false, false, 512, 108.8),
            C(467.2, 108.8, 423.74, 115.97, 383.42, 129.86))
        path()
          .d(M(332.8, 691.2), H(108.8), v(224))
        path()
          .d(M(108.8, 512), C(108.8, 400.45, 153.6, 299.65, 227.07, 227.07))
        path()
          .d(
            M(108.8, 691.2), l(101.25, 101.25), A(436.8, 436.8, 0, false, false, 512, 915.2),
            c(111.55, 0, 212.35, -44.8, 284.93, -118.27))
        path()
          .d(M(915.2, 512), c(0, 44.8, -7.17, 88.26, -21.06, 128.58))
        path()
          .d(M(915.2, 108.8), v(224), h(-224))
        path()
          .d(M(960, 960), L(64, 64))
      }
      .class(`class`.isEmpty ? "lucide-refresh-cw-off-icon-view" : "lucide-refresh-cw-off-icon-view \(`class`)")
      .style {
        height(iconSize)
        selector(IconHoverMotion.hover(), IconHoverMotion.focus()) {
          animation(
            "lucide-refresh-cw-off-shake calc(\(transitionDurationBase.value) * 4) \(animationTimingFunctionBouncing.value)")
          media(prefersReducedMotion(.reduce)) { animation("none").important() }
        }
        keyframes("lucide-refresh-cw-off-shake") {
          at(perc(20)) { CSS.Property("transform", "translateX(-6%)") }
          at(perc(40)) { CSS.Property("transform", "translateX(6%)") }
          at(perc(60)) { CSS.Property("transform", "translateX(-6%)") }
          at(perc(80)) { CSS.Property("transform", "translateX(6%)") }
        }
      }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeWidth(128)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .ariaHidden(true)
      .build()
    }
  }
#endif
