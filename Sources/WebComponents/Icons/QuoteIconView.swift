#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `quote` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `quote` (ISC;
  /// THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct QuoteIconView: HTMLContent {
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
        path().d("M718.87 46.55A103.43 103.43 0 0 0 615.43 149.98L615.43 460.28A103.43 103.43 0 0 0 718.87 563.72A51.72 51.72 0 0 1 770.59 615.43L770.59 667.15A103.43 103.43 0 0 1 667.15 770.59A51.72 51.72 0 0 0 615.43 822.3L615.43 925.74A51.72 51.72 0 0 0 667.15 977.45A310.3 310.3 0 0 0 977.45 667.15L977.45 149.98A103.43 103.43 0 0 0 874.02 46.55Z")
        path().d("M149.98 46.55A103.43 103.43 0 0 0 46.55 149.98L46.55 460.28A103.43 103.43 0 0 0 149.98 563.72A51.72 51.72 0 0 1 201.7 615.43L201.7 667.15A103.43 103.43 0 0 1 98.26 770.59A51.72 51.72 0 0 0 46.55 822.3L46.55 925.74A51.72 51.72 0 0 0 98.26 977.45A310.3 310.3 0 0 0 408.57 667.15L408.57 149.98A103.43 103.43 0 0 0 305.13 46.55Z")
      }
      .class(stringIsEmpty(`class`) ? "quote-icon-view" : "quote-icon-view \(`class`)")
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
