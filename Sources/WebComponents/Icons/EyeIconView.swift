import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `eye` (ISC; THIRD_PARTY_NOTICES.md): Unhide: show a hidden locution again; an action button's verb mark. Lucide's own
/// 24-grid geometry (lucide-static 1.60.0), fitted to the house box by
/// IconStrokeFit: the long edge 1024, `iconStrokeWidth` thick, round caps
/// and joins, the outer edges tight to the box.
/// SERVER + CLIENT: client code renders it too.
public struct EyeIconView: HTMLContent {
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
    let fit = IconStrokeFit(minX: 2, minY: 5, maxX: 22, maxY: 19)
    return svg {
      g {
        path().d("M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0")
        circle().cx(12).cy(12).r(3)
      }
      .transform(fit.transform)
      .strokeWidth(fit.strokeWidth)
    }
    .class(stringIsEmpty(`class`) ? "eye-icon-view" : "eye-icon-view \(`class`)")
    .style { width(iconSize) }
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

  public enum EyeIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = EyeIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
