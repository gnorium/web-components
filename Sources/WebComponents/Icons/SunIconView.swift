#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `sun` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `sun` (ISC;
  /// THIRD_PARTY_NOTICES.md), for the light color scheme. Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct SunIconView: HTMLContent {
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
        circle().cx(512).cy(512).r(186.18)
        path().d("M512 46.55L512 139.64")
        path().d("M512 884.36L512 977.45")
        path().d("M182.92 182.92L248.55 248.55")
        path().d("M775.45 775.45L841.08 841.08")
        path().d("M46.55 512L139.64 512")
        path().d("M884.36 512L977.45 512")
        path().d("M248.55 775.45L182.92 841.08")
        path().d("M841.08 182.92L775.45 248.55")
      }
      .class(stringIsEmpty(`class`) ? "sun-icon-view" : "sun-icon-view \(`class`)")
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
