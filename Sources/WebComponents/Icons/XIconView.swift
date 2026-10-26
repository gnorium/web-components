import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `x` (ISC; THIRD_PARTY_NOTICES.md): the × of a close or dismiss
/// control, never a status mark (a failure is `octagon-alert`). Lucide's own
/// geometry (lucide-static 1.60.0), carried flat into the house box: the long
/// edge 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight
/// to the box (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct XIconView: HTMLContent {
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
      path().d("M977.45 46.55L46.55 977.45")
      path().d("M46.55 46.55L977.45 977.45")
    }
    .class(stringIsEmpty(`class`) ? "x-icon-view" : "x-icon-view \(`class`)")
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

  public enum XIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = XIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
