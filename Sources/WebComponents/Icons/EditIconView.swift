#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct EditIconView: HTMLContent {
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
            M(897.1, 398.25), l(110.36, -113.77), a(56.89, 56.89, 0, false, false, 0, -80.21),
            l(-190, -187.73), a(56.89, 56.89, 0, false, false, -80.21, 0), L(625.75, 126.9), Z(),
            M(0, 753.79), V(1024), h(270.21), l(566.59, -566.59), l(-270.21, -270.21), Z())
      }
      .class(`class`.isEmpty ? "edit-icon-view" : "edit-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.currentColor)

    }
  }
#endif
