#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct UpTriangleIconView: HTMLContent {
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
          .d(M(512, 0), l(512, 640), H(0), Z())
      }
      .class(`class`.isEmpty ? "up-triangle-icon-view" : "up-triangle-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 640)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
