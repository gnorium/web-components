#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Codex `image`: a picture frame with a mountain in it.
  public struct ImageIconView: HTMLContent {
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
            M(102.4, 0), a(102.4, 102.4, 0, false, false, -102.4, 102.4), v(614.4),
            a(102.4, 102.4, 0, false, false, 102.4, 102.4), h(819.2),
            a(102.4, 102.4, 0, false, false, 102.4, -102.4), V(102.4),
            a(102.4, 102.4, 0, false, false, -102.4, -102.4), Z(), m(-8.7, 665.6), l(209.4, -268.8),
            l(149.51, 179.71), L(661.5, 307.2), l(268.8, 358.4), Z())
      }
      .class(`class`.isEmpty ? "image-icon-view" : "image-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 819.2)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
