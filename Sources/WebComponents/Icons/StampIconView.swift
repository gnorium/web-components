import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `stamp` (ISC; THIRD_PARTY_NOTICES.md): permitted: the object
/// stamped into its record (a status mark, green—the only green). Lucide's own
/// geometry (lucide-static 1.60.0), carried flat into the house box: the long
/// edge 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight
/// to the box (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct StampIconView: HTMLContent {
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
      path().d("M512 558.55L512 349.09C512 279.27 558.55 279.27 558.55 186.18A139.63 139.63 0 0 0 279.27 186.18C279.27 279.27 325.82 279.27 325.82 349.09L325.82 558.55")
      path().d("M791.27 674.91A116.36 116.36 0 0 0 674.91 558.55L162.91 558.55A116.36 116.36 0 0 0 46.55 674.91L46.55 744.73A46.55 46.55 0 0 0 93.09 791.27L744.73 791.27A46.55 46.55 0 0 0 791.27 744.73Z")
      path().d("M93.09 977.45L744.73 977.45")
    }
    .class(stringIsEmpty(`class`) ? "stamp-icon-view" : "stamp-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 837.82, 1024)
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

  public enum StampIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = StampIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
