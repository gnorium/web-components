import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `pause` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `pause` (ISC;
/// THIRD_PARTY_NOTICES.md), to hold a replay where it stands (user,
/// 2026-10-21). Lucide's own geometry (lucide-static 1.60.0), carried flat into
/// the house box: the long edge 1024, the house stroke (`iconStrokeWidth`),
/// round caps and joins, tight to the box (user, 2026-10-26). SERVER + CLIENT
/// for PauseIconFactory: the replay's Pause/Play swaps it.
public struct PauseIconView: HTMLContent {
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
      rect().x(512).y(46.55).width(258.59).height(930.91).rx(51.72)
      rect().x(46.55).y(46.55).width(258.59).height(930.91).rx(51.72)
    }
    .class(stringIsEmpty(`class`) ? "pause-icon-view" : "pause-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 817.13, 1024)
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

  public enum PauseIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = PauseIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
