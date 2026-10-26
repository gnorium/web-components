#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `settings` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `settings`
  /// (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static
  /// 1.60.0), carried flat into the house box: the long edge 1024, the house
  /// stroke (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct SettingsIconView: HTMLContent {
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
        path().d("M355.57 145.33A109.11 109.11 0 0 1 572.82 145.33A109.11 109.11 0 0 0 727.58 234.63A109.11 109.11 0 0 1 836.22 422.68A109.11 109.11 0 0 0 836.22 601.32A109.11 109.11 0 0 1 727.58 789.37A109.11 109.11 0 0 0 572.82 878.67A109.11 109.11 0 0 1 355.57 878.67A109.11 109.11 0 0 0 200.76 789.37A109.11 109.11 0 0 1 92.12 601.32A109.11 109.11 0 0 0 92.12 422.68A109.11 109.11 0 0 1 200.72 234.63A109.11 109.11 0 0 0 355.48 145.33")
        circle().cx(464.17).cy(512.02).r(139.89)
      }
      .class(stringIsEmpty(`class`) ? "settings-icon-view" : "settings-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 928.34, 1024)
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
