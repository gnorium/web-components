#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ClockIconView: HTMLContent {
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
            M(512, 0), a(512, 512, 0, true, false, 512, 512), A(512, 512, 0, false, false, 512, 0),
            m(128, 742.4), L(460.8, 563.2), V(204.8), h(102.4), v(307.2), l(153.6, 153.6), Z())
      }
      .class(`class`.isEmpty ? "clock-icon-view" : "clock-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
