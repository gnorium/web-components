#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct CancelIconView: HTMLContent {
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
            M(512, 0), a(512, 512, 0, true, false, 512, 512), A(512, 512, 0, false, false, 512, 0),
            M(102.4, 512), a(409.6, 409.6, 0, false, true, 86.53, -250.88), L(762.88, 835.07),
            A(409.6, 409.6, 0, false, true, 102.4, 512), m(732.67, 250.88), L(261.12, 188.93),
            A(409.6, 409.6, 0, false, true, 835.07, 762.88))
      }
      .class(`class`.isEmpty ? "cancel-icon-view" : "cancel-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
