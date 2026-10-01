#if SERVER
  import CSSBuilder
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
            M(471.89, 40.39), L(630.61, 199.11), H(284.44), v(56.89), h(346.17), l(-158.72, 159),
            L(512, 455.11), l(227.56, -227.55), l(-227.56, -227.56), Z())
        // Codex arrowPrevious.svg
        path()
          .d(
            M(552.11, 983.61), L(393.39, 824.89), H(739.56), V(768), H(393.39), L(552.11, 609),
            L(512, 568.89), L(284.44, 796.44), L(512, 1024), Z())
      }
      .class(`class`.isEmpty ? "swap-icon-view" : "swap-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
