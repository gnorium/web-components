#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct UploadIconView: HTMLContent {
    let width: CSS.Length
    let height: CSS.Length
    let `class`: String

    public init(
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      class: String = ""
    ) {
      self.width = width
      self.height = height
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
            M(512, 0), L(227.56, 341.33), h(227.55), v(455.11), h(113.78), V(341.33), h(227.55),
            Z())
      }
      .class(`class`.isEmpty ? "upload-icon-view" : "upload-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
