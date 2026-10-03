#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Two opposite arrows with the same 128/1024 line weight as the
  /// standalone arrow icons. Extended tails fill a square without scaling
  /// the arrowheads or changing their line weight.
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
        path()
          .d(M(0, 256), H(928), M(736, 64), L(928, 256), L(736, 448))
        path()
          .d(M(1024, 768), H(96), M(288, 576), L(96, 768), L(288, 960))
      }
      .class(`class`.isEmpty ? "swap-icon-view" : "swap-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeWidth(128)
      .strokeLinecap(.butt)
      .strokeLinejoin(.miter)
    }
  }
#endif
