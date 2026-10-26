import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `thumbs-up` (ISC; THIRD_PARTY_NOTICES.md): Accept: a revision's
/// verdict in its favor; an action button's verb mark. Lucide's own geometry
/// (lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct ThumbsUpIconView: HTMLContent {
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
      path().d("M651.64 227.14L605.09 418.91L876.45 418.91A93.09 93.09 0 0 1 965.82 538.07L857.37 910.43A93.09 93.09 0 0 1 768 977.45L139.64 977.45A93.09 93.09 0 0 1 46.55 884.36L46.55 512A93.09 93.09 0 0 1 139.64 418.91L268.1 418.91A93.09 93.09 0 0 0 351.42 367.24L512 46.55A145.69 145.69 0 0 1 651.64 227.14Z")
      path().d("M279.27 418.91L279.27 977.45")
    }
    .class(stringIsEmpty(`class`) ? "thumbs-up-icon-view" : "thumbs-up-icon-view \(`class`)")
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

  public enum ThumbsUpIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = ThumbsUpIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
