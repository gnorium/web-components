#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `image` (ISC; THIRD_PARTY_NOTICES.md): a picture frame with a
  /// mountain in it. Lucide's own geometry (lucide-static 1.60.0), carried flat
  /// into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct ImageIconView: HTMLContent {
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
        rect().x(46.55).y(46.55).width(930.91).height(930.91).rx(103.43)
        circle().cx(356.85).cy(356.85).r(103.43)
        path().d("M977.45 667.15L817.86 507.55A103.43 103.43 0 0 0 671.6 507.55L201.7 977.45")
      }
      .class(stringIsEmpty(`class`) ? "image-icon-view" : "image-icon-view \(`class`)")
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
