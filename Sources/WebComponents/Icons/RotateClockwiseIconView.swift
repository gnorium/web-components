#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `rotate-cw` (ISC; THIRD_PARTY_NOTICES.md): Circular reload /
  /// rerun mark. Lucide's own geometry (lucide-static 1.60.0), carried flat
  /// into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct RotateClockwiseIconView: HTMLContent {
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
        path().d("M977.45 512A465.45 465.45 0 1 1 512 46.55C642.33 46.55 766.97 98.26 860.57 188.25L977.45 305.13")
        path().d("M977.45 46.55L977.45 305.13L718.87 305.13")
      }
      .class(stringIsEmpty(`class`) ? "rotate-clockwise-icon-view" : "rotate-clockwise-icon-view \(`class`)")
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
