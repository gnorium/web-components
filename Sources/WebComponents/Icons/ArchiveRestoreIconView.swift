import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `archive-restore` (ISC; THIRD_PARTY_NOTICES.md): Recover: take a
/// discarded object back; an action button's verb mark. Lucide's own geometry
/// (lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26). SERVER + CLIENT: client code renders it too.
public struct ArchiveRestoreIconView: HTMLContent {
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
      rect().x(46.55).y(46.55).width(930.91).height(232.73).rx(46.55)
      path().d("M139.64 279.27L139.64 791.27A93.09 93.09 0 0 0 232.73 884.36L325.82 884.36")
      path().d("M884.36 279.27L884.36 791.27A93.09 93.09 0 0 1 791.27 884.36L698.18 884.36")
      path().d("M372.36 605.09L512 465.45L651.64 605.09")
      path().d("M512 465.45L512 884.36")
    }
    .class(stringIsEmpty(`class`) ? "archive-restore-icon-view" : "archive-restore-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 930.91)
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

  public enum ArchiveRestoreIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = ArchiveRestoreIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
