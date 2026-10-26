import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `gavel` (ISC; THIRD_PARTY_NOTICES.md): committed: the object went
/// on to its next process (a status mark, blue). Lucide's own geometry
/// (lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct GavelIconView: HTMLContent {
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
      path().d("M605.15 558.46L215.11 948.45A46.53 46.53 0 0 1 75.45 808.84L465.63 418.8")
      path().d("M698.23 698.08L977.45 418.85")
      path().d("M954.19 442.12L581.88 69.81")
      path().d("M325.92 325.77L605.15 46.55")
      path().d("M349.19 302.5L721.5 674.81")
    }
    .class(stringIsEmpty(`class`) ? "gavel-icon-view" : "gavel-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 1023.93)
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

  public enum GavelIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = GavelIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
