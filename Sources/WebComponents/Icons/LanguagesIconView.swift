#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `languages` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `languages`
  /// (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static
  /// 1.60.0), carried flat into the house box: the long edge 1024, the house
  /// stroke (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct LanguagesIconView: HTMLContent {
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
        path().d("M186.18 325.82L465.45 605.09")
        path().d("M139.64 605.09L418.91 325.82L512 186.18")
        path().d("M46.55 186.18L605.09 186.18")
        path().d("M279.27 46.55L325.82 46.55")
        path().d("M977.45 977.45L744.73 512L512 977.45")
        path().d("M605.09 791.27L884.36 791.27")
      }
      .class(stringIsEmpty(`class`) ? "languages-icon-view" : "languages-icon-view \(`class`)")
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
