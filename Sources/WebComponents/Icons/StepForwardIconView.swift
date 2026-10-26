import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `step-forward` (ISC; THIRD_PARTY_NOTICES.md): Continue: take a
/// stopped session on from where it left off; an action button's verb mark.
/// Lucide's own geometry (lucide-static 1.60.0), carried flat into the house
/// box: the long edge 1024, the house stroke (`iconStrokeWidth`), round caps
/// and joins, tight to the box (user, 2026-10-26). SERVER + CLIENT: client code
/// renders it too.
public struct StepForwardIconView: HTMLContent {
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
      path().d("M410.06 61.29A103.43 103.43 0 0 0 253.41 149.98L253.41 770.58A103.43 103.43 0 0 0 410.06 859.27L927.07 549.08A103.43 103.43 0 0 0 927.23 371.59Z")
      path().d("M46.55 46.55L46.55 874.01")
    }
    .class(stringIsEmpty(`class`) ? "step-forward-icon-view" : "step-forward-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 920.56)
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

  public enum StepForwardIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = StepForwardIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
