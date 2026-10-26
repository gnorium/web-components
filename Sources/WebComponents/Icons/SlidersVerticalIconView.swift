#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `sliders-vertical` (ISC; THIRD_PARTY_NOTICES.md): Lucide's
  /// `sliders-vertical` (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct SlidersVerticalIconView: HTMLContent {
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
        path().d("M408.57 305.13L615.43 305.13")
        path().d("M512 977.45L512 512")
        path().d("M512 305.13L512 46.55")
        path().d("M770.59 718.87L977.45 718.87")
        path().d("M874.02 512L874.02 46.55")
        path().d("M874.02 977.45L874.02 718.87")
        path().d("M46.55 615.43L253.41 615.43")
        path().d("M149.98 408.57L149.98 46.55")
        path().d("M149.98 977.45L149.98 615.43")
      }
      .class(stringIsEmpty(`class`) ? "sliders-vertical-icon-view" : "sliders-vertical-icon-view \(`class`)")
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
