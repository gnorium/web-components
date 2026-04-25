#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct UploadIconView: HTMLContent {
    let width: Length
    let height: Length
    let `class`: String

    public init(
      width: Length = px(20),
      height: Length = px(20),
      class: String = ""
    ) {
      self.width = width
      self.height = height
      self.class = `class`
    }

    public func render() -> Node {
      svg {
        path()
          .d(
            M(17, 12), v(5), H(3), v(-5), H(1), v(5), a(2, 2, 0, false, false, 2, 2), h(14),
            a(2, 2, 0, false, false, 2, -2), v(-5), Z())

        path()
          .d(M(10, 1), L(5, 7), h(4), v(8), h(2), V(7), h(4), Z())
      }
      .class(`class`.isEmpty ? "upload-icon-view" : "upload-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
