#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct UserAvatarIconView: HTMLContent {
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
            M(512, 568.89), c(-336.78, 0, -455.11, 170.67, -455.11, 284.44), v(170.67), h(910.22),
            v(-170.67), c(0, -113.77, -118.33, -284.44, -455.11, -284.44))

        circle()
          .cx(512)
          .cy(256)
          .r(256)
      }
      .class(`class`.isEmpty ? "user-avatar-icon-view" : "user-avatar-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
