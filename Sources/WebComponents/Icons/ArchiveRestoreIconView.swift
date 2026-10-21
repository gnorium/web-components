import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `archive-restore` (ISC; THIRD_PARTY_NOTICES.md): Recover: take a discarded object back; an action button's verb mark. Lucide's own
/// 24-grid geometry (lucide-static 1.60.0), fitted to the house box by
/// IconStrokeFit: the long edge 1024, `iconStrokeWidth` thick, round caps
/// and joins, the outer edges tight to the box.
/// SERVER + CLIENT: client code renders it too.
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
    let fit = IconStrokeFit(minX: 2, minY: 3, maxX: 22, maxY: 21)
    return svg {
      g {
        path().d("M3 3h18a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z")
        path().d("M4 8v11a2 2 0 0 0 2 2h2")
        path().d("M20 8v11a2 2 0 0 1-2 2h-2")
        path().d("m9 15 3-3 3 3")
        path().d("M12 12v9")
      }
      .transform(fit.transform)
      .strokeWidth(fit.strokeWidth)
    }
    .class(stringIsEmpty(`class`) ? "archive-restore-icon-view" : "archive-restore-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, fit.width, fit.height)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.none)
    .stroke(.currentColor)
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
