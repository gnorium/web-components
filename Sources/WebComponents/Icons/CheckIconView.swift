import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `check` (ISC; THIRD_PARTY_NOTICES.md): a done or chosen thing:
/// submitted, a status mark (blue), a menu's chosen item, a copied code block.
/// Lucide's own geometry (lucide-static 1.60.0), carried flat into the house
/// box: the long edge 1024, the house stroke (`iconStrokeWidth`), round caps
/// and joins, tight to the box (user, 2026-10-26). SERVER + CLIENT: client code
/// renders it too.
public struct CheckIconView: HTMLContent {
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
      path().d("M977.45 46.55L337.45 686.55L46.55 395.64")
    }
    .class(stringIsEmpty(`class`) ? "check-icon-view" : "check-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 733.09)
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

  public enum CheckIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = CheckIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
