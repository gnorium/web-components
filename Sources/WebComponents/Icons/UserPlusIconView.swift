import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `user-plus` (ISC; THIRD_PARTY_NOTICES.md): Register: add a person;
/// an action button's verb mark. Lucide's own geometry (lucide-static 1.60.0),
/// carried flat into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct UserPlusIconView: HTMLContent {
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
      path().d("M698.18 884.36L698.18 791.27A186.18 186.18 0 0 0 512 605.09L232.73 605.09A186.18 186.18 0 0 0 46.55 791.27L46.55 884.36")
      circle().cx(372.36).cy(232.73).r(186.18)
      path().d("M837.82 279.27L837.82 558.55")
      path().d("M977.45 418.91L698.18 418.91")
    }
    .class(stringIsEmpty(`class`) ? "user-plus-icon-view" : "user-plus-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 930.91)
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

  public enum UserPlusIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = UserPlusIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
