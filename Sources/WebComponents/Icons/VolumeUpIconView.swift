#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct VolumeUpIconView: HTMLContent {
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
            M(205.23, 306.77), v(410.46), l(266.8, 200.1), c(15.39, 15.39, 41.05, 0, 41.05, -25.65),
            V(132.32), c(0, -25.65, -25.66, -41.04, -41.05, -25.65), Z(), m(0, 410.46), H(51.31),
            a(51.31, 51.31, 0, false, true, -51.31, -51.31), V(358.08),
            a(51.31, 51.31, 0, false, true, 51.31, -51.31), h(153.92), m(636.22, 584.91),
            a(51.31, 51.31, 0, false, true, -35.92, -87.23),
            a(410.46, 410.46, 0, false, false, 0, -584.9),
            A(51.31, 51.31, 0, false, true, 872.23, 152.85),
            a(513.08, 513.08, 0, false, true, 0, 728.57),
            a(51.31, 51.31, 0, false, true, -35.91, 15.39), Z())

        path()
          .d(
            M(692.66, 742.89), a(51.31, 51.31, 0, false, true, -35.92, -15.4),
            a(51.31, 51.31, 0, false, true, 0, -71.83),
            a(205.23, 205.23, 0, false, false, 0, -287.32),
            a(51.31, 51.31, 0, false, true, 71.83, -71.83),
            a(307.85, 307.85, 0, false, true, 0, 430.98),
            a(51.31, 51.31, 0, false, true, -35.91, 15.4))
      }
      .class(`class`.isEmpty ? "volume-up-icon-view" : "volume-up-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
