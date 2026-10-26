#if SERVER
  import HTMLBuilder
  import SVGBuilder
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebTypes

  /// Lucide's `circle-question-mark` (ISC; THIRD_PARTY_NOTICES.md): Lucide's
  /// `circle-question-mark` (ISC; THIRD_PARTY_NOTICES.md). Lucide's own
  /// geometry (lucide-static 1.60.0), carried flat into the house box: the long
  /// edge 1024, the house stroke (`iconStrokeWidth`), round caps and joins,
  /// tight to the box (user, 2026-10-26).
  public struct CircleQuestionMarkIconView: HTMLContent {
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
        path().d("M376.55 372.36A139.64 139.64 0 0 1 647.91 418.91C647.91 512 508.28 558.55 508.28 558.55")
        path().d("M512 744.73L512.47 744.73")
      }
      .class(stringIsEmpty(`class`) ? "circle-question-mark-icon-view" : "circle-question-mark-icon-view \(`class`)")
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
