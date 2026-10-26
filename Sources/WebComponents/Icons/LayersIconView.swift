import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `layers` (ISC; THIRD_PARTY_NOTICES.md): a vignette: the quiet mark
/// of what is published over what came before. Lucide's own geometry
/// (lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct LayersIconView: HTMLContent {
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
      path().d("M550.22 54.93A93.01 93.01 0 0 0 473.01 54.93L74.45 236.31A46.51 46.51 0 0 0 74.45 321.42L473.48 503.26A93.01 93.01 0 0 0 550.68 503.26L949.71 321.88A46.51 46.51 0 0 0 949.71 236.78Z")
      path().d("M46.55 511.63A46.51 46.51 0 0 0 73.52 553.95L473.48 735.8A93.01 93.01 0 0 0 550.22 735.8L949.25 554.42A46.51 46.51 0 0 0 976.69 511.63")
      path().d("M46.55 744.17A46.51 46.51 0 0 0 73.52 786.49L473.48 968.33A93.01 93.01 0 0 0 550.22 968.33L949.25 786.95A46.51 46.51 0 0 0 976.69 744.17")
    }
    .class(stringIsEmpty(`class`) ? "layers-icon-view" : "layers-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 1023.16)
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

  public enum LayersIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = LayersIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
