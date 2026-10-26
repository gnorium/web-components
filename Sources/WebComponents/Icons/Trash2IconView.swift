import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `trash-2` (ISC; THIRD_PARTY_NOTICES.md): Discard: a reversible
/// removal; an action button's verb mark. Lucide's own geometry (lucide-static
/// 1.60.0), carried flat into the house box: the long edge 1024, the house
/// stroke (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct Trash2IconView: HTMLContent {
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
      path().d("M372.36 465.45L372.36 744.73")
      path().d("M558.55 465.45L558.55 744.73")
      path().d("M791.27 232.73L791.27 884.36A93.09 93.09 0 0 1 698.18 977.45L232.73 977.45A93.09 93.09 0 0 1 139.64 884.36L139.64 232.73")
      path().d("M46.55 232.73L884.36 232.73")
      path().d("M279.27 232.73L279.27 139.64A93.09 93.09 0 0 1 372.36 46.55L558.55 46.55A93.09 93.09 0 0 1 651.64 139.64L651.64 232.73")
    }
    .class(stringIsEmpty(`class`) ? "trash-2-icon-view" : "trash-2-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 930.91, 1024)
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

  public enum Trash2IconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = Trash2IconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
