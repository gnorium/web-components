import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `undo-2` (ISC; THIRD_PARTY_NOTICES.md): Revert: undo an accepted
/// revision; an action button's verb mark. Lucide's own geometry (lucide-static
/// 1.60.0), carried flat into the house box: the long edge 1024, the house
/// stroke (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct Undo2IconView: HTMLContent {
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
      path().d("M337.45 628.36L46.55 337.45L337.45 46.55")
      path().d("M46.55 337.45L657.45 337.45A320 320 0 0 1 977.45 657.45A320 320 0 0 1 657.45 977.45L453.82 977.45")
    }
    .class(stringIsEmpty(`class`) ? "undo-2-icon-view" : "undo-2-icon-view \(`class`)")
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

  public enum Undo2IconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = Undo2IconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
