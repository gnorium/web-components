#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// The Codex text flow icon (lines of text, ragged), drawn edge to edge in its view box.
  public struct TextFlowIconView: HTMLContent {
    let iconSize: CSS.Length

    public init(size: CSS.Length) {
      self.iconSize = size
    }

    public func build() -> DOM.Node {
      svg {
        path().d(
          M(0, 0), h(1024), v(113.78), H(0), z(), m(0, 227.56), h(796.44), v(113.78), H(0), z(),
          m(0, 227.56), h(568.89), v(113.78), H(0), z(), m(0, 227.56), h(1024), v(113.78), H(0), z())
      }
      .class("text-flow-icon-view")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 796.44)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
      .ariaHidden(true)
      .build()
    }
  }
#endif
