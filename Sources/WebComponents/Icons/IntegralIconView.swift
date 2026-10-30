import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `integral` (ISC; THIRD_PARTY_NOTICES.md): the integration
/// subprocess badge (`∫`). Lucide's own geometry (Lucide Lab; not in
/// lucide-static 1.60.0), carried flat into the house box: the long edge 1024,
/// the house stroke (`iconStrokeWidth`), round caps and joins, tight to the box
/// (user, 2026-10-26). `weight` thickens the stroke beside semibold type
/// (`IconWeight`, user 2026-10-30): the path stands, the box grows by the
/// stroke's growth, so the stroke is its share of the long edge.
/// SERVER + CLIENT: client code renders it too.
public struct IntegralIconView: HTMLContent {
  let iconSize: CSS.Length
  let weight: IconWeight
  let `class`: String

  public init(
    size: CSS.Length,
    weight: IconWeight = .regular,
    class: String = ""
  ) {
    self.iconSize = size
    self.weight = weight
    self.class = `class`
  }

  public func build() -> DOM.Node {
    // The path's own extent less its regular stroke (930.91 tall); the stroke its share of the long edge
    // that extent and the stroke make (93.09 regular: 1024 tall).
    let stroke = weight.share * 930.91 / (1 - weight.share)
    let grown = (stroke - 93.09) / 2
    return svg {
      path().d("M418.91 139.64A93.09 93.09 0 0 0 232.73 139.64L232.73 884.36A93.09 93.09 0 0 1 46.55 884.36")
    }
    .class(stringIsEmpty(`class`) ? "integral-icon-view" : "integral-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(-grown, -grown, 465.45 + 2 * grown, 1024 + 2 * grown)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.none)
    .stroke(.currentColor)
    .strokeWidth(stroke)
    .strokeLinecap(.round)
    .strokeLinejoin(.round)
    .ariaHidden(true)
    .build()
  }
}

#if CLIENT
  import WebAPIs

  public enum IntegralIconFactory {
    public static func createElement(
      size: CSS.Length,
      weight: IconWeight = .regular,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = IntegralIconView(size: size, weight: weight, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
