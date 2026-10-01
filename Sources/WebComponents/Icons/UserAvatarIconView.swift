#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct UserAvatarIconView: HTMLContent {
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
            M(455.11, 568.89), c(-336.78, 0, -455.11, 170.67, -455.11, 284.44), v(170.67),
            h(910.22), v(-170.67), c(0, -113.77, -118.33, -284.44, -455.11, -284.44))

        circle()
          .cx(455.11)
          .cy(256)
          .r(256)
      }
      .class(`class`.isEmpty ? "user-avatar-icon-view" : "user-avatar-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 910.22, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
