#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Swap: two ends traded, ⇄. Codex has no swap icon; this composes two
  /// Codex icons unchanged, `arrowNext.svg` directly above
  /// `arrowPrevious.svg`: both at 0.5 (8 × 8), centered on the box's middle
  /// column, 2 apart, 1 from the top and the bottom.
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
      svg {
        // Codex arrowNext.svg
        path()
          .d(
            M(187.45, 40.39), L(346.17, 199.11), H(0), v(56.89), h(346.17), l(-158.72, 159),
            L(227.56, 455.11), l(227.55, -227.55), l(-227.55, -227.56), Z())
        // Codex arrowPrevious.svg
        path()
          .d(
            M(267.66, 983.61), L(108.94, 824.89), H(455.11), V(768), H(108.94), L(267.66, 609),
            L(227.56, 568.89), L(0, 796.44), L(227.56, 1024), Z())
      }
      .class(`class`.isEmpty ? "swap-icon-view" : "swap-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 455.11, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
