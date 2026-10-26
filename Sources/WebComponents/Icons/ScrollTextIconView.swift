import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `scroll-text` (ISC; THIRD_PARTY_NOTICES.md): ported, not yet
/// placed. Lucide's own geometry (lucide-static 1.60.0), carried flat into the
/// house box: the long edge 1024, the house stroke (`iconStrokeWidth`), round
/// caps and joins, tight to the box (user, 2026-10-26). SERVER + CLIENT: client
/// code renders it too.
public struct ScrollTextIconView: HTMLContent {
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
      path().d("M651.64 465.45L418.91 465.45")
      path().d("M651.64 279.27L418.91 279.27")
      path().d("M837.82 698.18L837.82 139.64A93.09 93.09 0 0 0 744.73 46.55L139.64 46.55")
      path().d("M325.82 884.36L884.36 884.36A93.09 93.09 0 0 0 977.45 791.27L977.45 744.73A46.55 46.55 0 0 0 930.91 698.18L465.45 698.18A46.55 46.55 0 0 0 418.91 744.73L418.91 791.27A93.09 93.09 0 1 1 232.73 791.27L232.73 139.64A93.09 93.09 0 1 0 46.55 139.64L46.55 232.73A46.55 46.55 0 0 0 93.09 279.27L232.73 279.27")
    }
    .class(stringIsEmpty(`class`) ? "scroll-text-icon-view" : "scroll-text-icon-view \(`class`)")
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

  public enum ScrollTextIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = ScrollTextIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
