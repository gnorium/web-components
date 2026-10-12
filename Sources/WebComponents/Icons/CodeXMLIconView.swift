#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `code-xml` (`</>`) (ISC; THIRD_PARTY_NOTICES.md), the Raw switch of
  /// a TEI/XML source. Lucide's
  /// own 24-grid geometry, fitted to the house box by IconStrokeFit: the
  /// long edge 1024, `iconStrokeWidth` thick, round caps and joins, the
  /// outer edges tight to the box (user, 2026-10-12).
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
      let fit = IconStrokeFit(minX: 2, minY: 4, maxX: 22, maxY: 20)
      return svg {
        g {
          path().d(M(18, 16), l(4, -4), l(-4, -4))
          path().d(M(6, 8), l(-4, 4), l(4, 4))
          path().d(M(14.5, 4), l(-5, 16))
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "code-xml-icon-view" : "code-xml-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, fit.width, fit.height)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .ariaHidden(true)
      .build()
    }
  }
#endif
