#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `text-wrap` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `text-wrap`
  /// (`wrap-text` before Lucide renamed it) (ISC; THIRD_PARTY_NOTICES.md), for
  /// Reflow. Lucide writes the turn as `a1 1 0 0 1 0 7`, a radius the renderer
  /// grows to the half chord; here it is that radius, 3.5, outright. Lucide's
  /// own geometry (lucide-static 1.60.0), carried flat into the house box: the
  /// long edge 1024, the house stroke (`iconStrokeWidth`), round caps and
  /// joins, tight to the box (user, 2026-10-26).
  public struct TextWrapIconView: HTMLContent {
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
        path().d("M718.87 615.43L563.72 770.59L718.87 925.74")
        path().d("M46.55 408.57L796.44 408.57A51.71 51.71 0 0 1 796.44 770.59L563.72 770.59")
        path().d("M46.55 770.59L356.85 770.59")
        path().d("M46.55 46.55L977.45 46.55")
      }
      .class(stringIsEmpty(`class`) ? "text-wrap-icon-view" : "text-wrap-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 972.28)
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
