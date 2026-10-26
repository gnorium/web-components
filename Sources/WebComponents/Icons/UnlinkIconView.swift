import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `unlink` (ISC; THIRD_PARTY_NOTICES.md): Disconnect: end a link to
/// an outside account; an action button's verb mark. Lucide's own geometry
/// (lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct UnlinkIconView: HTMLContent {
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
      path().d("M830.37 523.64L910.43 444.04L909.5 444.04A232.91 232.91 0 0 0 903.91 114.97A233.01 233.01 0 0 0 580.42 114.97L500.36 194.56")
      path().d("M194.09 500.36L114.5 579.96A232.91 232.91 0 0 0 120.09 909.03A233.01 233.01 0 0 0 443.58 909.03L523.17 829.44")
      path().d("M325.82 46.55L325.82 186.18")
      path().d("M46.55 325.82L186.18 325.82")
      path().d("M698.18 837.82L698.18 977.45")
      path().d("M837.82 698.18L977.45 698.18")
    }
    .class(stringIsEmpty(`class`) ? "unlink-icon-view" : "unlink-icon-view \(`class`)")
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

#if CLIENT
  import WebAPIs

  public enum UnlinkIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = UnlinkIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
