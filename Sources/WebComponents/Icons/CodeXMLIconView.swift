#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `code-xml` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `code-xml`
  /// (`</>`) (ISC; THIRD_PARTY_NOTICES.md), the Raw switch of a TEI/XML source.
  /// Lucide's own geometry (lucide-static 1.60.0), carried flat into the house
  /// box: the long edge 1024, the house stroke (`iconStrokeWidth`), round caps
  /// and joins, tight to the box (user, 2026-10-26).
  public struct CodeXMLIconView: HTMLContent {
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
        path().d("M791.27 605.09L977.45 418.91L791.27 232.73")
        path().d("M232.73 232.73L46.55 418.91L232.73 605.09")
        path().d("M628.36 46.55L395.64 791.27")
      }
      .class(stringIsEmpty(`class`) ? "code-xml-icon-view" : "code-xml-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 837.82)
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
