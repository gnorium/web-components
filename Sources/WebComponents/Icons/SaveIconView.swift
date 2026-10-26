import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `save` (ISC; THIRD_PARTY_NOTICES.md): Save: keep what was entered;
/// an action button's verb mark. Lucide's own geometry (lucide-static 1.60.0),
/// carried flat into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct SaveIconView: HTMLContent {
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
      path().d("M677.49 46.55A103.43 103.43 0 0 1 749.9 77.58L946.42 274.1A103.43 103.43 0 0 1 977.45 346.51L977.45 874.02A103.43 103.43 0 0 1 874.02 977.45L149.98 977.45A103.43 103.43 0 0 1 46.55 874.02L46.55 149.98A103.43 103.43 0 0 1 149.98 46.55Z")
      path().d("M770.59 977.45L770.59 615.43A51.72 51.72 0 0 0 718.87 563.72L305.13 563.72A51.72 51.72 0 0 0 253.41 615.43L253.41 977.45")
      path().d("M253.41 46.55L253.41 253.41A51.72 51.72 0 0 0 305.13 305.13L667.15 305.13")
    }
    .class(stringIsEmpty(`class`) ? "save-icon-view" : "save-icon-view \(`class`)")
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

  public enum SaveIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = SaveIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
