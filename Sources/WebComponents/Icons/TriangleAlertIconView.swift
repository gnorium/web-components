import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `triangle-alert` (ISC; THIRD_PARTY_NOTICES.md): a warning: an
/// orange alert, a stale figure. Lucide's own geometry (lucide-static 1.60.0),
/// carried flat into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct TriangleAlertIconView: HTMLContent {
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
      path().d("M964.99 744.82L592.93 93.7A93.02 93.02 0 0 0 431.08 93.7L59.01 744.82A93.02 93.02 0 0 0 140.4 884.34L884.53 884.34A93.02 93.02 0 0 0 964.99 744.82")
      path().d("M512.47 326.24L512.47 512.28")
      path().d("M512.47 698.31L512.93 698.31")
    }
    .class(stringIsEmpty(`class`) ? "triangle-alert-icon-view" : "triangle-alert-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 930.89)
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

  public enum TriangleAlertIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = TriangleAlertIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
