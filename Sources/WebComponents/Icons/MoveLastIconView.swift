#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import SVGBuilder
  import HTMLBuilder
  import DOMBuilder
  import WebTypes

  public struct MoveLastIconView: HTMLContent {
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
            M(654.22, 0), h(113.78), v(1024), h(-113.78), Z(), M(0, 85.33), L(426.67, 512),
            l(-426.67, 426.67), L(85.33, 1024), l(512, -512), l(-512, -512), Z())
      }
      .class(`class`.isEmpty ? "move-last-icon-view" : "move-last-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 768, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
