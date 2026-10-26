import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `octagon-alert` (ISC; THIRD_PARTY_NOTICES.md): an error: a red
/// alert, a field's error, a failed or nullified status mark. Lucide's own
/// geometry (lucide-static 1.60.0), carried flat into the house box: the long
/// edge 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight
/// to the box (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct OctagonAlertIconView: HTMLContent {
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
      path().d("M512 698.18L512.47 698.18")
      path().d("M512 325.82L512 512")
      path().d("M666.16 46.55A93.09 93.09 0 0 1 731.97 73.82L950.18 292.03A93.09 93.09 0 0 1 977.45 357.84L977.45 666.16A93.09 93.09 0 0 1 950.18 731.97L731.97 950.18A93.09 93.09 0 0 1 666.16 977.45L357.84 977.45A93.09 93.09 0 0 1 292.03 950.18L73.82 731.97A93.09 93.09 0 0 1 46.55 666.16L46.55 357.84A93.09 93.09 0 0 1 73.82 292.03L292.03 73.82A93.09 93.09 0 0 1 357.84 46.55Z")
    }
    .class(stringIsEmpty(`class`) ? "octagon-alert-icon-view" : "octagon-alert-icon-view \(`class`)")
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

  public enum OctagonAlertIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = OctagonAlertIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
