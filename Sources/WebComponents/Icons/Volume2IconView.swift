#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `volume-2` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `volume-2`
  /// (ISC; THIRD_PARTY_NOTICES.md). Lucide's own geometry (lucide-static
  /// 1.60.0), carried flat into the house box: the long edge 1024, the house
  /// stroke (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct Volume2IconView: HTMLContent {
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
        path().d("M465.45 79.31A32.81 32.81 0 0 0 409.46 56.13L251.95 213.6A65.16 65.16 0 0 1 205.54 232.82L93.09 232.82A46.55 46.55 0 0 0 46.55 279.36L46.55 558.64A46.55 46.55 0 0 0 93.09 605.18L205.54 605.18A65.16 65.16 0 0 1 251.95 624.4L409.41 781.91A32.81 32.81 0 0 0 465.45 758.69Z")
        path().d("M698.18 279.36A232.73 232.73 0 0 1 698.18 558.64")
        path().d("M854.76 715.21A418.91 418.91 0 0 0 854.76 122.79")
      }
      .class(stringIsEmpty(`class`) ? "volume-2-icon-view" : "volume-2-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 838.09)
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
