#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// The Codex link icon, drawn edge to edge in its view box.
  public struct LinkIconView: HTMLContent {
    let iconSize: CSS.Length

    public init(size: CSS.Length) {
      self.iconSize = size
    }

    public func build() -> DOM.Node {
      svg {
        path().d(
          M(247.3, 512), h(148.99), a(250.88, 250.88, 0, false, true, -79.36, -102.4), H(256),
          a(153.59, 153.59, 0, true, true, 0, -307.2), h(153.6),
          a(153.6, 153.6, 0, false, true, 144.38, 204.8), h(107.52),
          a(256, 256, 0, false, false, 4.1, -42.5), v(-17.4),
          A(247.3, 247.3, 0, false, false, 418.3, 0), H(247.3),
          A(247.3, 247.3, 0, false, false, 0, 247.3), v(17.4),
          A(247.3, 247.3, 0, false, false, 247.3, 512))
        path().d(
          M(776.7, 0), h(-148.99), a(250.88, 250.88, 0, false, true, 79.36, 102.4), H(768),
          a(153.59, 153.59, 0, true, true, 0, 307.2), h(-153.6),
          a(153.6, 153.6, 0, false, true, -144.38, -204.8), h(-107.52),
          a(256, 256, 0, false, false, -4.1, 42.5), v(17.4),
          A(247.3, 247.3, 0, false, false, 605.7, 512), h(171),
          A(247.3, 247.3, 0, false, false, 1024, 264.7), v(-17.4),
          A(247.3, 247.3, 0, false, false, 776.7, 0))
      }
      .class("link-icon-view")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 512)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
      .ariaHidden(true)
      .build()
    }
  }
#endif
