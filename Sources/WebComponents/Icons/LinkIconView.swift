#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// The Codex link icon, with geometry centered in its view box.
  public struct LinkIconView: HTMLContent {
    public init() {}

    public func build() -> DOM.Node {
      svg {
        path().d(
          M(4.83, 15), h(2.91), a(4.9, 4.9, 0, false, true, -1.55, -2), H(5),
          a(3, 3, 0, true, true, 0, -6), h(3), a(3, 3, 0, false, true, 2.82, 4),
          h(2.1), a(5, 5, 0, false, false, 0.08, -0.83), v(-0.34),
          A(4.83, 4.83, 0, false, false, 8.17, 5), H(4.83),
          A(4.83, 4.83, 0, false, false, 0, 9.83), v(0.34),
          A(4.83, 4.83, 0, false, false, 4.83, 15))
        path().d(
          M(15.17, 5), h(-2.91), a(4.9, 4.9, 0, false, true, 1.55, 2), H(15),
          a(3, 3, 0, true, true, 0, 6), h(-3), a(3, 3, 0, false, true, -2.82, -4),
          h(-2.1), a(5, 5, 0, false, false, -0.08, 0.83), v(0.34),
          A(4.83, 4.83, 0, false, false, 11.83, 15), h(3.34),
          A(4.83, 4.83, 0, false, false, 20, 10.17), v(-0.34),
          A(4.83, 4.83, 0, false, false, 15.17, 5))
      }
      .class("link-icon-view")
      .width(px(20))
      .height(px(20))
      .viewBox(0, 0, 20, 20)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
      .ariaHidden(true)
      .build()
    }
  }
#endif
