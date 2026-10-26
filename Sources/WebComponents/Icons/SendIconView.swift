import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `send` (ISC; THIRD_PARTY_NOTICES.md): Send: deliver a message; an
/// action button's verb mark. Lucide's own geometry (lucide-static 1.60.0),
/// carried flat into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct SendIconView: HTMLContent {
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
      path().d("M629.96 962.85A23.27 23.27 0 0 0 673.57 961.73L976.08 77.47A23.08 23.08 0 0 0 946.53 47.92L62.27 350.43A23.27 23.27 0 0 0 61.15 394.04L430.21 542.03A93.08 93.08 0 0 1 481.97 593.69Z")
      path().d("M970.54 53.5L461.39 562.61")
    }
    .class(stringIsEmpty(`class`) ? "send-icon-view" : "send-icon-view \(`class`)")
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

  public enum SendIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = SendIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
