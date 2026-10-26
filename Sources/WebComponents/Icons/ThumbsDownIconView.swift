import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `thumbs-down` (ISC; THIRD_PARTY_NOTICES.md): Reject: a revision's
/// verdict against it; an action button's verb mark. Lucide's own geometry
/// (lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct ThumbsDownIconView: HTMLContent {
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
      path().d("M364.45 796.86L411 605.09L139.64 605.09A93.09 93.09 0 0 1 50.27 485.93L158.72 113.57A93.09 93.09 0 0 1 248.09 46.55L876.45 46.55A93.09 93.09 0 0 1 969.54 139.64L969.54 512A93.09 93.09 0 0 1 876.45 605.09L747.99 605.09A93.09 93.09 0 0 0 664.67 656.76L504.09 977.45A145.69 145.69 0 0 1 364.45 796.86Z")
      path().d("M736.81 605.09L736.81 46.55")
    }
    .class(stringIsEmpty(`class`) ? "thumbs-down-icon-view" : "thumbs-down-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 1016.09, 1024)
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

  public enum ThumbsDownIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = ThumbsDownIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
