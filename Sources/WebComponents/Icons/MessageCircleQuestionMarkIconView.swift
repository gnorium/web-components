#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `message-circle-question-mark` (ISC; THIRD_PARTY_NOTICES.md):
  /// Lucide's `message-circle-question-mark` (ISC; THIRD_PARTY_NOTICES.md).
  /// Lucide's own geometry (lucide-static 1.60.0), carried flat into the house
  /// box: the long edge 1024, the house stroke (`iconStrokeWidth`), round caps
  /// and joins, tight to the box (user, 2026-10-26).
  public struct MessageCircleQuestionMarkIconView: HTMLContent {
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
        path().d("M92.7 714.08A93.09 93.09 0 0 1 97.08 768.4L47.51 921.53A46.55 46.55 0 0 0 105.04 975.9L263.9 929.45A93.09 93.09 0 0 1 315.05 933.73A465.45 465.45 0 1 0 92.7 714.08")
        path().d("M376.54 372.35A139.64 139.64 0 0 1 647.89 418.89C647.89 511.98 508.26 558.53 508.26 558.53")
        path().d("M511.98 744.71L512.45 744.71")
      }
      .class(stringIsEmpty(`class`) ? "message-circle-question-mark-icon-view" : "message-circle-question-mark-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1023.99, 1024)
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
