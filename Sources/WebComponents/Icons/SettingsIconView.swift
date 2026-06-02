#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct SettingsIconView: HTMLContent {
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
        g {
          path()
            .id("a")
            .d(M(1.5, -10), h(-3), l(-1, 6.5), h(5), m(0, 7), h(-5), l(1, 6.5), h(3))

          use()
            .href("#a")
            .transform(rotate(45))

          use()
            .href("#a")
            .transform(rotate(90))

          use()
            .href("#a")
            .transform(rotate(135))
        }
        .xmlnsXlink("http://www.w3.org/1999/xlink")
        .transform(translate(10, 10))

        path()
          .d(
            M(10, 2.5), a(7.5, 7.5, 0, false, false, 0, 15), a(7.5, 7.5, 0, false, false, 0, -15),
            v(4), a(3.5, 3.5, 0, false, true, 0, 7), a(3.5, 3.5, 0, false, true, 0, -7))
      }
      .class(`class`.isEmpty ? "settings-icon-view" : "settings-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
