#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Swap: two ends traded, ⇄. Codex has no swap icon; this composes two
  /// Codex icons unchanged, `arrowNext.svg` above `arrowPrevious.svg`, each
  /// at 0.7 and staggered so the heads clear each other.
  public struct SwapIconView: HTMLContent {
    let width: CSS.Length
    let height: CSS.Length
    let `class`: String

    public init(
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      class: String = ""
    ) {
      self.width = width
      self.height = height
      self.class = `class`
    }

    public func build() -> DOM.Node {
      svg {
        // Codex arrowNext.svg
        path()
          .d(
            M(8.59, 3.42), L(14.17, 9), H(2), v(2), h(12.17), l(-5.58, 5.59), L(10, 18), l(8, -8),
            l(-8, -8), Z())
          .transform(translate(5, -1.2), scale(0.7))
        // Codex arrowPrevious.svg
        path()
          .d(
            M(11.41, 16.58), L(5.83, 11), H(18), V(9), H(5.83), L(11.41, 3.41), L(10, 2), L(2, 10),
            L(10, 18), Z())
          .transform(translate(1, 7.4), scale(0.7))
      }
      .class(`class`.isEmpty ? "swap-icon-view" : "swap-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
