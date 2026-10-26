import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `house` (ISC; THIRD_PARTY_NOTICES.md): Home: the way back to the
/// site's front page; a link button's mark. Lucide's own geometry
/// (lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct HouseIconView: HTMLContent {
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
      path().d("M634.47 977.45L634.47 585.5A48.99 48.99 0 0 0 585.48 536.51L389.5 536.51A48.99 48.99 0 0 0 340.51 585.5L340.51 977.45")
      path().d("M46.55 438.52A97.99 97.99 0 0 1 81.28 363.66L424.24 69.69A97.99 97.99 0 0 1 550.74 69.69L893.7 363.66A97.99 97.99 0 0 1 928.44 438.52L928.44 879.47A97.99 97.99 0 0 1 830.45 977.45L144.53 977.45A97.99 97.99 0 0 1 46.55 879.47Z")
    }
    .class(stringIsEmpty(`class`) ? "house-icon-view" : "house-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 974.98, 1024)
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

  public enum HouseIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = HouseIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
