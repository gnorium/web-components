#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct FlagIconView: HTMLContent {
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
          .d(M(796.44, 284.44), L(0, 0), v(1024), h(113.78), v(-390.83), Z())
      }
      .class(`class`.isEmpty ? "flag-icon-view" : "flag-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 796.44, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
