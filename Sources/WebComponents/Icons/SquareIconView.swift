import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `square` (ISC; THIRD_PARTY_NOTICES.md): Stop: end what is running;
/// an action button's verb mark (Lucide's rect drawn as the equal path).
/// Lucide's own geometry (lucide-static 1.60.0), carried flat into the house
/// box: the long edge 1024, the house stroke (`iconStrokeWidth`), round caps
/// and joins, tight to the box (user, 2026-10-26). SERVER + CLIENT: client code
/// renders it too.
public struct SquareIconView: HTMLContent {
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
      rect().x(46.55).y(46.55).width(930.91).height(930.91).rx(103.43)
    }
    .class(stringIsEmpty(`class`) ? "square-icon-view" : "square-icon-view \(`class`)")
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

  public enum SquareIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = SquareIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
