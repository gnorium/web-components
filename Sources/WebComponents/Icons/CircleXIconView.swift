#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `circle-x` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `circle-x`
  /// (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static
  /// 1.60.0), carried flat into the house box: the long edge 1024, the house
  /// stroke (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct CircleXIconView: HTMLContent {
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
        circle().cx(512).cy(512).r(465.45)
        path().d("M651.64 372.36L372.36 651.64")
        path().d("M372.36 372.36L651.64 651.64")
      }
      .class(stringIsEmpty(`class`) ? "circle-x-icon-view" : "circle-x-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeWidth(93.09)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .ariaHidden(true)
      .build()
    }
  }
#endif
