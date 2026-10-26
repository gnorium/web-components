import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `rotate-ccw` (ISC; THIRD_PARTY_NOTICES.md): Replay: run a recorded
/// session again from its start; an action button's verb mark. Lucide's own
/// geometry (lucide-static 1.60.0), carried flat into the house box: the long
/// edge 1024, the house stroke (`iconStrokeWidth`), round caps and joins, tight
/// to the box (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct RotateCounterclockwiseIconView: HTMLContent {
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
      path().d("M46.55 512A465.45 465.45 0 1 0 512 46.55A504.24 504.24 0 0 0 163.43 188.25L46.55 305.13")
      path().d("M46.55 46.55L46.55 305.13L305.13 305.13")
    }
    .class(stringIsEmpty(`class`) ? "rotate-counterclockwise-icon-view" : "rotate-counterclockwise-icon-view \(`class`)")
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

  public enum RotateCounterclockwiseIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = RotateCounterclockwiseIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
