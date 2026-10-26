#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `minimize` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `minimize`
  /// (ISC; THIRD_PARTY_NOTICES.md), to leave full screen. Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct MinimizeIconView: HTMLContent {
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
        path().d("M305.13 46.55L305.13 201.7A103.43 103.43 0 0 1 201.7 305.13L46.55 305.13")
        path().d("M977.45 305.13L822.3 305.13A103.43 103.43 0 0 1 718.87 201.7L718.87 46.55")
        path().d("M46.55 718.87L201.7 718.87A103.43 103.43 0 0 1 305.13 822.3L305.13 977.45")
        path().d("M718.87 977.45L718.87 822.3A103.43 103.43 0 0 1 822.3 718.87L977.45 718.87")
      }
      .class(stringIsEmpty(`class`) ? "minimize-icon-view" : "minimize-icon-view \(`class`)")
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
