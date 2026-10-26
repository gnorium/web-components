#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `external-link` (ISC; THIRD_PARTY_NOTICES.md): Lucide's
  /// `external-link` (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct ExternalLinkIconView: HTMLContent {
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
        path().d("M667.15 46.55L977.45 46.55L977.45 356.85")
        path().d("M408.57 615.43L977.45 46.55")
        path().d("M822.3 563.72L822.3 874.02A103.43 103.43 0 0 1 718.87 977.45L149.98 977.45A103.43 103.43 0 0 1 46.55 874.02L46.55 305.13A103.43 103.43 0 0 1 149.98 201.7L460.28 201.7")
      }
      .class(stringIsEmpty(`class`) ? "external-link-icon-view" : "external-link-icon-view \(`class`)")
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
