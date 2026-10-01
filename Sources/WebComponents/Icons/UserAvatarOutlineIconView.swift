#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct UserAvatarOutlineIconView: HTMLContent {
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
            M(512, 409.6), c(87.04, 0, 156.67, -69.12, 156.67, -153.6),
            S(599.04, 102.4, 512, 102.4), S(355.33, 171.52, 355.33, 256),
            S(424.96, 409.6, 512, 409.6), m(0, 102.4),
            c(-143.36, 0, -259.07, -114.69, -259.07, -256), S(368.64, 0, 512, 0),
            s(259.07, 114.69, 259.07, 256), s(-115.71, 256, -259.07, 256), m(-358.4, 409.6),
            h(716.8), v(-68.1), c(0, -89.6, -118.27, -182.27, -358.4, -182.27),
            s(-358.4, 92.67, -358.4, 182.27), Z(), m(358.4, -352.77),
            c(340.99, 0, 460.8, 170.5, 460.8, 284.67), V(1024), H(51.2), v(-170.5),
            c(0, -114.17, 119.81, -284.67, 460.8, -284.67))
      }
      .class(
        `class`.isEmpty
          ? "user-avatar-outline-icon-view" : "user-avatar-outline-icon-view \(`class`)"
      )
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
