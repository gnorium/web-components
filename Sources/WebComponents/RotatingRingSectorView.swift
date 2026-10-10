import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// A rotating 120° ring sector, representing a translation layer loading.
public struct RotatingRingSectorView: HTMLContent {
  let size: CSS.Length
  let ariaHidden: Bool
  let ariaLabel: String
  let `class`: String

  public init(
    size: CSS.Length = sizeIconSmall,
    ariaHidden: Bool = false,
    ariaLabel: String = "Translation layer loading",
    class: String = ""
  ) {
    self.size = size
    self.ariaHidden = ariaHidden
    self.ariaLabel = ariaLabel
    self.class = `class`
  }

  public func build() -> DOM.Node {
    svg {
      path()
        .d(M(512, 64), A(448, 448, 0, false, true, 899.979, 736))
        .class("rotating-ring-sector-shape")
        .fill(.none)
        .stroke(.currentColor)
        .strokeWidth(128)
    }
    .class(stringIsEmpty(`class`) ? "rotating-ring-sector-view" : "rotating-ring-sector-view \(`class`)")
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .role("progressbar")
    .ariaHidden(ariaHidden)
    .ariaLabel(ariaHidden ? nil : ariaLabel)
    .style {
      width(size)
      height(size)
      selector("&") { display(.inlineBlock); flexShrink(0) }
      child(".rotating-ring-sector-shape") {
        transformOrigin(perc(50), perc(50))
        animation("rotating-ring-sector-spin", animationDurationFast, animationTimingFunctionBase, .infinite)
        media(prefersReducedMotion(.reduce)) { animation("none") }
      }
      keyframes("rotating-ring-sector-spin") {
        from { transform(rotate(deg(0))) }
        to { transform(rotate(deg(360))) }
      }
    }
  }
}

#if CLIENT
  import WebAPIs

  public enum RotatingRingSectorFactory {
    public static func createElement(
      size: CSS.Length = sizeIconSmall,
      ariaHidden: Bool = true,
      class: String = ""
    ) -> DOM.Element {
      StyleSheetLoader.ensure("rotating-ring-sector-view")
      let wrapper = document.createElement(.span)
      wrapper.innerHTML = RotatingRingSectorView(
        size: size, ariaHidden: ariaHidden, class: `class`
      ).render()
      if let leaf = wrapper.firstElementChild { return leaf }
      return wrapper
    }
  }
#endif
