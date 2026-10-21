import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `eye-off` (ISC; THIRD_PARTY_NOTICES.md): Hide: keep a locution from view; an action button's verb mark. Lucide's own
/// 24-grid geometry (lucide-static 1.60.0), fitted to the house box by
/// IconStrokeFit: the long edge 1024, `iconStrokeWidth` thick, round caps
/// and joins, the outer edges tight to the box.
/// SERVER + CLIENT: client code renders it too.
public struct EyeOffIconView: HTMLContent {
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
        path().d("M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49")
        path().d("M14.084 14.158a3 3 0 0 1-4.242-4.242")
        path().d("M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143")
        path().d("m2 2 20 20")
      }
      .transform(fit.transform)
      .strokeWidth(fit.strokeWidth)
    }
    .class(stringIsEmpty(`class`) ? "eye-off-icon-view" : "eye-off-icon-view \(`class`)")
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

  public enum EyeOffIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = EyeOffIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
