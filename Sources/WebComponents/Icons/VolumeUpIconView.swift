#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct VolumeUpIconView: HTMLContent {
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
            M(205.23, 206.24), v(410.46), l(266.8, 200.1), c(15.39, 15.4, 41.05, 0, 41.05, -25.65),
            V(31.8), c(0, -25.66, -25.66, -41.05, -41.05, -25.66), Z(), m(0, 410.46), H(51.31),
            a(51.31, 51.31, 0, false, true, -51.31, -51.3), V(257.55),
            a(51.31, 51.31, 0, false, true, 51.31, -51.31), h(153.92), m(636.22, 584.91),
            a(51.31, 51.31, 0, false, true, -35.92, -87.22),
            a(410.46, 410.46, 0, false, false, 0, -584.91),
            A(51.31, 51.31, 0, false, true, 872.23, 52.32),
            a(513.08, 513.08, 0, false, true, 0, 728.57),
            a(51.31, 51.31, 0, false, true, -35.91, 15.39), Z())

        path()
          .d(
            M(692.66, 642.36), a(51.31, 51.31, 0, false, true, -35.92, -15.39),
            a(51.31, 51.31, 0, false, true, 0, -71.84),
            a(205.23, 205.23, 0, false, false, 0, -287.32),
            a(51.31, 51.31, 0, false, true, 71.83, -71.83),
            a(307.85, 307.85, 0, false, true, 0, 430.99),
            a(51.31, 51.31, 0, false, true, -35.91, 15.39))
      }
      .class(`class`.isEmpty ? "volume-up-icon-view" : "volume-up-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 822.95)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
