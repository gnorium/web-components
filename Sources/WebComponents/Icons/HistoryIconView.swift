#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct HistoryIconView: HTMLContent {
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
            M(470.49, 276.76), v(276.75), h(3.32), l(137.27, 136.72), l(78.04, -78.04),
            L(581.19, 504.25), V(276.76), Z())

        path()
          .d(
            M(525.84, 0), a(498.16, 498.16, 0, false, false, -434.51, 738.94), L(0, 830.27),
            H(304.43), v(-304.43), l(-131.73, 131.73),
            A(387.46, 387.46, 0, true, true, 525.84, 885.62), v(110.7),
            a(498.16, 498.16, 0, false, false, 0, -996.32))
      }
      .class(`class`.isEmpty ? "history-icon-view" : "history-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 996.32)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
