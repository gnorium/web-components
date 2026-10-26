#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `refresh-cw-off` (ISC; THIRD_PARTY_NOTICES.md): Lucide's
  /// `refresh-cw-off` (ISC; THIRD_PARTY_NOTICES.md), for detaching. Lucide's
  /// own geometry (lucide-static 1.60.0), carried flat into the house box: the
  /// long edge 1024, the house stroke (`iconStrokeWidth`), round caps and
  /// joins, tight to the box (user, 2026-10-26).
  public struct RefreshClockwiseOffIconView: HTMLContent {
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
        path().d("M930.91 325.82L825.72 220.63A453.82 453.82 0 0 0 512 93.09C465.45 93.09 420.31 100.54 378.41 114.97")
        path().d("M325.82 698.18L93.09 698.18L93.09 930.91")
        path().d("M93.09 512C93.09 396.1 139.64 291.37 215.97 215.97")
        path().d("M93.09 698.18L198.28 803.37A453.82 453.82 0 0 0 512 930.91C627.9 930.91 732.63 884.36 808.03 808.03")
        path().d("M930.91 512C930.91 558.55 923.46 603.69 909.03 645.59")
        path().d("M930.91 93.09L930.91 325.82L698.18 325.82")
        path().d("M977.45 977.45L46.55 46.55")
      }
      .class(stringIsEmpty(`class`) ? "refresh-clockwise-off-icon-view" : "refresh-clockwise-off-icon-view \(`class`)")
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
