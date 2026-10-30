import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `lightbulb` (ISC; THIRD_PARTY_NOTICES.md): Suggest: put a
/// revision forward for evaluation; an action button's verb mark (user,
/// 2026-10-30). Lucide's own geometry (lucide-static 1.60.0), carried flat
/// into the house box: the long edge 1024, the house stroke
/// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
/// 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct LightbulbIconView: HTMLContent {
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
      path().d("M465.45 605.09C474.76 558.55 498.04 525.96 535.27 488.73C581.82 446.84 605.09 386.33 605.09 325.82A279.27 279.27 0 0 0 46.55 325.82C46.55 372.36 55.85 428.22 116.36 488.73C148.95 521.31 176.87 558.55 186.18 605.09")
      path().d("M186.18 791.27L465.45 791.27")
      path().d("M232.73 977.45L418.91 977.45")
    }
    .class(stringIsEmpty(`class`) ? "lightbulb-icon-view" : "lightbulb-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 651.64, 1024)
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

  public enum LightbulbIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = LightbulbIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
