#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct HistoryIconView: HTMLContent {
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
        path()
          .d(
            M(470.49, 290.59), v(276.76), h(3.32), l(137.27, 136.72), l(78.04, -78.05),
            L(581.19, 518.09), V(290.59), Z())

        path()
          .d(
            M(525.84, 13.84), a(498.16, 498.16, 0, false, false, -434.51, 738.94), L(0, 844.11),
            H(304.43), v(-304.43), l(-131.73, 131.73),
            A(387.46, 387.46, 0, true, true, 525.84, 899.46), v(110.7),
            a(498.16, 498.16, 0, false, false, 0, -996.32))
      }
      .class(`class`.isEmpty ? "history-icon-view" : "history-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
