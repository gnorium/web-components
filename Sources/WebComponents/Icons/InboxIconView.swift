import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `inbox` (ISC; THIRD_PARTY_NOTICES.md): submitted: the object put in
/// the post for a verdict (a status mark, blue). Lucide's own geometry
/// (lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct InboxIconView: HTMLContent {
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
      path().d("M977.45 418.91L698.18 418.91L605.09 558.55L418.91 558.55L325.82 418.91L46.55 418.91")
      path().d("M207.13 98.21L46.55 418.91L46.55 698.18A93.09 93.09 0 0 0 139.64 791.27L884.36 791.27A93.09 93.09 0 0 0 977.45 698.18L977.45 418.91L816.87 98.21A93.09 93.09 0 0 0 733.56 46.55L290.44 46.55A93.09 93.09 0 0 0 207.13 98.21Z")
    }
    .class(stringIsEmpty(`class`) ? "inbox-icon-view" : "inbox-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 837.82)
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

  public enum InboxIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = InboxIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
