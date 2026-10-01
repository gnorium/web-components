#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct DraggableIconView: HTMLContent {
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
            M(0, 576), h(1024), v(128), H(0), Z(), m(0, -256), h(1024), v(128), H(0), Z(),
            m(704, 512), H(320), l(192, 192), Z(), M(320, 192), h(384), l(-192, -192), Z())
      }
      .class(`class`.isEmpty ? "draggable-icon-view" : "draggable-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
