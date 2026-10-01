#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct DownloadIconView: HTMLContent {
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
            M(910.22, 625.78), v(284.44), H(113.78), v(-284.44), H(0), v(284.44),
            a(113.78, 113.78, 0, false, false, 113.78, 113.78), h(796.44),
            a(113.78, 113.78, 0, false, false, 113.78, -113.78), v(-284.44), Z())

        path()
          .d(
            M(796.44, 455.11), h(-227.55), V(0), H(455.11), v(455.11), H(227.56), l(284.44, 341.33),
            Z())
      }
      .class(`class`.isEmpty ? "download-icon-view" : "download-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
