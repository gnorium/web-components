#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `moon` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `moon` (ISC;
  /// THIRD_PARTY_NOTICES.md), for the dark color scheme. Its bounds are the
  /// crescent's measured extremes, its horns' rounded tips included. Lucide's
  /// own geometry (lucide-static 1.60.0), carried flat into the house box: the
  /// long edge 1024, the house stroke (`iconStrokeWidth`), round caps and
  /// joins, tight to the box (user, 2026-10-26).
  public struct MoonIconView: HTMLContent {
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
        path().d("M977.42 536.78A465.77 465.77 0 1 1 487.16 46.58C508.12 45.44 519.09 70.39 507.97 88.14A310.52 310.52 0 0 0 935.86 516.03C953.66 504.91 978.56 515.82 977.42 536.78")
      }
      .class(stringIsEmpty(`class`) ? "moon-icon-view" : "moon-icon-view \(`class`)")
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
