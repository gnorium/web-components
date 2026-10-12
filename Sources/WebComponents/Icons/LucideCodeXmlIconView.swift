#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `code-xml` (`</>`, ISC; THIRD_PARTY_NOTICES.md), the Raw
  /// switch of a TEI/XML source. TRIAL port (user, 2026-10-12): Lucide's
  /// 24 geometry (x 2–22, y 4–20) scaled ×44.8 onto the house grid, a
  /// 128/1024 stroke with Lucide's round caps and joins, its outer edges
  /// tight to the box (1024 × 844.8).
  ///
  /// Hover (its host button's, or keyboard focus): the brackets lean out
  /// and back, as the animated Lucide set moves its folder-code brackets
  /// (pqoqubbw/icons, MIT)—each out by one Lucide unit and turned 8°,
  /// there and back once, the slash still.
  public struct LucideCodeXmlIconView: HTMLContent {
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
          .d(M(780.8, 601.6), l(179.2, -179.2), l(-179.2, -179.2))
          .class("lucide-code-xml-right")
        path()
          .d(M(243.2, 243.2), l(-179.2, 179.2), l(179.2, 179.2))
          .class("lucide-code-xml-left")
        path()
          .d(M(624, 64), l(-224, 716.8))
      }
      .class(`class`.isEmpty ? "lucide-code-xml-icon-view" : "lucide-code-xml-icon-view \(`class`)")
      .style {
        width(iconSize)
        // The brackets lean out past the tight box.
        overflow(.visible)
        selector("& .lucide-code-xml-left", "& .lucide-code-xml-right") {
          transformBox("fill-box")
          transformOrigin(perc(50))
        }
        selector(IconHoverMotion.hover(".lucide-code-xml-left"), IconHoverMotion.focus(".lucide-code-xml-left")) {
          animation(
            "lucide-code-xml-left-lean calc(\(transitionDurationMedium.value) * 2) \(animationTimingFunctionBouncing.value)")
          media(prefersReducedMotion(.reduce)) { animation("none").important() }
        }
        selector(IconHoverMotion.hover(".lucide-code-xml-right"), IconHoverMotion.focus(".lucide-code-xml-right")) {
          animation(
            "lucide-code-xml-right-lean calc(\(transitionDurationMedium.value) * 2) \(animationTimingFunctionBouncing.value)")
          media(prefersReducedMotion(.reduce)) { animation("none").important() }
        }
        keyframes("lucide-code-xml-left-lean") {
          at(perc(50)) { CSS.Property("transform", "translateX(-44.8px) rotate(8deg)") }
        }
        keyframes("lucide-code-xml-right-lean") {
          at(perc(50)) { CSS.Property("transform", "translateX(44.8px) rotate(-8deg)") }
        }
      }
      .viewBox(0, 0, 1024, 844.8)
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
