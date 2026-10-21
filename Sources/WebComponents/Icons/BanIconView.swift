import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `ban` (ISC; THIRD_PARTY_NOTICES.md): Nullify: strike a locution out; an action button's verb mark. Lucide's own
/// 24-grid geometry (lucide-static 1.60.0), fitted to the house box by
/// IconStrokeFit: the long edge 1024, `iconStrokeWidth` thick, round caps
/// and joins, the outer edges tight to the box.
/// SERVER + CLIENT: client code renders it too.
public struct BanIconView: HTMLContent {
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
        circle().cx(12).cy(12).r(10)
        path().d("M4.929 4.929 19.07 19.071")
      }
      .transform(fit.transform)
      .strokeWidth(fit.strokeWidth)
    }
    .class(stringIsEmpty(`class`) ? "ban-icon-view" : "ban-icon-view \(`class`)")
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

  public enum BanIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = BanIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
