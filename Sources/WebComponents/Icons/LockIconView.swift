#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Codex `lock` icon.
  public struct LockIconView: HTMLContent {
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
            M(720.38, 409.6), H(665.6), V(256), s(0, -256, -256, -256), s(-256, 256, -256, 256),
            v(153.6), H(98.82), A(98.82, 98.82, 0, false, false, 0, 508.42), v(417.28),
            A(98.82, 98.82, 0, false, false, 98.82, 1024), h(621.56),
            A(98.82, 98.82, 0, false, false, 819.2, 925.18), V(508.42),
            A(98.82, 98.82, 0, false, false, 720.38, 409.6), M(409.6, 819.2),
            a(102.4, 102.4, 0, true, true, 102.4, -102.4),
            a(102.4, 102.4, 0, false, true, -102.4, 102.4), m(153.6, -409.6), H(256), V(281.6),
            C(256, 204.8, 256, 102.4, 409.6, 102.4), s(153.6, 102.4, 153.6, 179.2), Z())
      }
      .class(`class`.isEmpty ? "lock-icon-view" : "lock-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 819.2, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
