import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `ban` (ISC; THIRD_PARTY_NOTICES.md): Nullify: strike a locution
/// out; an action button's verb mark. Lucide's own geometry (lucide-static
/// 1.60.0), carried flat into the house box: the long edge 1024, the house
/// stroke (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct BanIconView: HTMLContent {
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
      circle().cx(512).cy(512).r(465.45)
      path().d("M182.88 182.88L841.08 841.12")
    }
    .class(stringIsEmpty(`class`) ? "ban-icon-view" : "ban-icon-view \(`class`)")
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

  public enum BanIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = BanIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
