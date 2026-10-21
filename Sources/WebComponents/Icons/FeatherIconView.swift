import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `feather` (ISC; THIRD_PARTY_NOTICES.md): Revise: write the entry over again; an action button's verb mark. Lucide's own
/// 24-grid geometry (lucide-static 1.60.0), fitted to the house box by
/// IconStrokeFit: the long edge 1024, `iconStrokeWidth` thick, round caps
/// and joins, the outer edges tight to the box.
/// SERVER + CLIENT: client code renders it too.
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
    let fit = IconStrokeFit(minX: 2, minY: 2, maxX: 22, maxY: 22)
    return svg {
      g {
        path().d("M14.086 18.412A2 2 0 0 1 12.67 19H5v-7.672a2 2 0 0 1 .586-1.414L11.75 3.75a6 6 0 1 1 8.49 8.49z")
        path().d("M16 8 2 22")
        path().d("M17.488 15H9")
      }
      .transform(fit.transform)
      .strokeWidth(fit.strokeWidth)
    }
    .class(stringIsEmpty(`class`) ? "feather-icon-view" : "feather-icon-view \(`class`)")
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
