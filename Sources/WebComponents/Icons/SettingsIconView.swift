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
            .d(
              M(76.8, -512), h(-153.6), l(-51.2, 332.8), h(256), m(0, 358.4), h(-256),
              l(51.2, 332.8), h(153.6))

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
        .transform(translate(512, 512))

        path()
          .d(
            M(512, 128), a(384, 384, 0, false, false, 0, 768),
            a(384, 384, 0, false, false, 0, -768), v(204.8),
            a(179.2, 179.2, 0, false, true, 0, 358.4), a(179.2, 179.2, 0, false, true, 0, -358.4))
      }
      .class(`class`.isEmpty ? "settings-icon-view" : "settings-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
