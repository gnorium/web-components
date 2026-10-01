#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct ExpandIconView: HTMLContent {
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
            M(85.33, 0), l(426.67, 426.67), l(426.67, -426.67), l(85.33, 85.33), l(-512, 512),
            l(-512, -512), Z())
      }
      .class(`class`.isEmpty ? "expand-icon-view" : "expand-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 597.33)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
