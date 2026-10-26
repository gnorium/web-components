import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `integral` (ISC; THIRD_PARTY_NOTICES.md): the integration
/// subprocess badge (`∫`). Lucide's own geometry (Lucide Lab; not in
/// lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct IntegralIconView: HTMLContent {
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
      path().d("M418.91 139.64A93.09 93.09 0 0 0 232.73 139.64L232.73 884.36A93.09 93.09 0 0 1 46.55 884.36")
    }
    .class(stringIsEmpty(`class`) ? "integral-icon-view" : "integral-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 465.45, 1024)
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

  public enum IntegralIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = IntegralIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
