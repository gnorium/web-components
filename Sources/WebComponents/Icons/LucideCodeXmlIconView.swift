#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `code-xml` (`</>`, ISC; THIRD_PARTY_NOTICES.md), the Raw
  /// switch of a TEI/XML source. TRIAL port (user, 2026-10-12): Lucide's
  /// 24 geometry (x 2–22, y 4–20) scaled ×44.8 onto the house grid, a
  /// 128/1024 stroke with Lucide's round caps and joins, its outer edges
  /// tight to the box (1024 × 844.8).
  public struct LucideCodeXmlIconView: HTMLContent {
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
          .d(M(780.8, 601.6), l(179.2, -179.2), l(-179.2, -179.2))
        path()
          .d(M(243.2, 243.2), l(-179.2, 179.2), l(179.2, 179.2))
        path()
          .d(M(624, 64), l(-224, 716.8))
      }
      .class(`class`.isEmpty ? "lucide-code-xml-icon-view" : "lucide-code-xml-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 844.8)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeWidth(128)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .ariaHidden(true)
      .build()
    }
  }
#endif
