import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `feather` (ISC; THIRD_PARTY_NOTICES.md): Revise: write the entry
/// over again; an action button's verb mark. Lucide's own geometry
/// (lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct FeatherIconView: HTMLContent {
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
      path().d("M608.86 810.52A93.05 93.05 0 0 1 542.98 837.88L186.12 837.88L186.12 480.93A93.05 93.05 0 0 1 213.39 415.14L500.17 128.35A279.15 279.15 0 1 1 895.18 523.36Z")
      path().d("M697.91 326.09L46.55 977.45")
      path().d("M767.14 651.77L372.23 651.77")
    }
    .class(stringIsEmpty(`class`) ? "feather-icon-view" : "feather-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 1023.53, 1024)
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

  public enum FeatherIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = FeatherIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
