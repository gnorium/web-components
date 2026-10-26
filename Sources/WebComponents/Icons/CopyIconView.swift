import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `copy` (ISC; THIRD_PARTY_NOTICES.md): Overlapping-rectangles copy
/// glyph. Lucide's own geometry (lucide-static 1.60.0), carried flat into the
/// house box: the long edge 1024, the house stroke (`iconStrokeWidth`), round
/// caps and joins, tight to the box (user, 2026-10-26). Available on SERVER +
/// CLIENT for CopyIconFactory.
public struct CopyIconView: HTMLContent {
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
      rect().x(325.82).y(325.82).width(651.64).height(651.64).rx(93.09)
      path().d("M139.64 698.18C88.44 698.18 46.55 656.29 46.55 605.09L46.55 139.64C46.55 88.44 88.44 46.55 139.64 46.55L605.09 46.55C656.29 46.55 698.18 88.44 698.18 139.64")
    }
    .class(stringIsEmpty(`class`) ? "copy-icon-view" : "copy-icon-view \(`class`)")
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

  public enum CopyIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = CopyIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
