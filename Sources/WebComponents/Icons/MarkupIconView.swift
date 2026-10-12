#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// The Codex markup icon (`<>`), drawn edge to edge in its view box.
  public struct MarkupIconView: HTMLContent {
    let iconSize: CSS.Length

    public init(size: CSS.Length) {
      self.iconSize = size
    }

    public func build() -> DOM.Node {
      svg {
        path().d(
          M(332.8, 0), L(0, 332.8), l(76.8, 76.8), l(256, 256), L(409.6, 588.8), l(-256, -256), l(256, -256), z(),
          m(358.4, 0), L(614.4, 76.8), l(256, 256), l(-256, 256), l(76.8, 76.8), L(1024, 332.8), z())
      }
      .class("markup-icon-view")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 665.6)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
      .ariaHidden(true)
      .build()
    }
  }
#endif
