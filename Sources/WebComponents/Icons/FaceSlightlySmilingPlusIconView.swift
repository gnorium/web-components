#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `face-slightly-smiling-plus` (ISC; THIRD_PARTY_NOTICES.md):
  /// Lucide's `face-slightly-smiling-plus` (ISC; THIRD_PARTY_NOTICES.md),
  /// formerly `smile-plus`, for adding a reaction. Lucide's own geometry
  /// (lucide-static 1.60.0), carried flat into the house box: the long edge
  /// 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight to
  /// the box (user, 2026-10-26).
  public struct FaceSlightlySmilingPlusIconView: HTMLContent {
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
        path().d("M570.95 50.29A465.45 465.45 0 1 0 973.71 453.05")
        path().d("M651.61 418.93L651.61 372.39")
        path().d("M698.16 186.21L977.43 186.21")
        path().d("M720.13 651.66A279.27 279.27 0 0 1 303.87 651.66")
        path().d("M837.79 46.57L837.79 325.84")
        path().d("M372.34 418.93L372.34 372.39")
      }
      .class(stringIsEmpty(`class`) ? "face-slightly-smiling-plus-icon-view" : "face-slightly-smiling-plus-icon-view \(`class`)")
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
