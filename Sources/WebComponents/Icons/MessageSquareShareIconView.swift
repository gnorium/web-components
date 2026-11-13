import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `message-square-share` (ISC; THIRD_PARTY_NOTICES.md): Suggest: a
/// revision put to the thread, the bubble Revise wears with its arrow out
/// (user, 2026-11-13). Lucide's own geometry (lucide-static 1.60.0), carried
/// flat into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct MessageSquareShareIconView: HTMLContent {
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
      path().d("M512 46.55L139.64 46.55A93.09 93.09 0 0 0 46.55 139.64L46.55 897.68A33.05 33.05 0 0 0 102.96 921.04L205.45 818.55A93.09 93.09 0 0 1 271.27 791.27L884.36 791.27A93.09 93.09 0 0 0 977.45 698.18L977.45 512")
      path().d("M698.18 46.55L977.45 46.55L977.45 325.82")
      path().d("M698.18 325.82L977.45 46.55")
    }
    .class(stringIsEmpty(`class`) ? "message-square-share-icon-view" : "message-square-share-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 977.26)
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

  public enum MessageSquareShareIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = MessageSquareShareIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
