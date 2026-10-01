#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Codex `lock` icon.
  public struct LockIconView: HTMLContent {
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
            M(822.78, 409.6), H(768), V(256), s(0, -256, -256, -256), s(-256, 256, -256, 256),
            v(153.6), H(201.22), A(98.82, 98.82, 0, false, false, 102.4, 508.42), v(417.28),
            A(98.82, 98.82, 0, false, false, 201.22, 1024), h(621.56),
            A(98.82, 98.82, 0, false, false, 921.6, 925.18), V(508.42),
            A(98.82, 98.82, 0, false, false, 822.78, 409.6), M(512, 819.2),
            a(102.4, 102.4, 0, true, true, 102.4, -102.4),
            a(102.4, 102.4, 0, false, true, -102.4, 102.4), m(153.6, -409.6), H(358.4), V(281.6),
            C(358.4, 204.8, 358.4, 102.4, 512, 102.4), s(153.6, 102.4, 153.6, 179.2), Z())
      }
      .class(`class`.isEmpty ? "lock-icon-view" : "lock-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)
    }
  }
#endif
