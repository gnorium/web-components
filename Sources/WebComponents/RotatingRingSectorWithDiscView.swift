import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// A static disc with a rotating ring sector, representing translation in progress.
public struct RotatingRingSectorWithDiscView: HTMLContent {
  let size: CSS.Length
  let ariaHidden: Bool
  let ariaLabel: String
  let `class`: String

  public init(
    size: CSS.Length = spacing8,
    ariaHidden: Bool = false,
    ariaLabel: String = "Translation running",
    class: String = ""
  ) {
    self.size = size
    self.ariaHidden = ariaHidden
    self.ariaLabel = ariaLabel
    self.class = `class`
  }

  public func build() -> DOM.Node {
    svg {
      // These are siblings: neither the disc nor its ancestor ever rotates.
      circle().cx(512).cy(512).r(256).class("rotating-ring-sector-with-disc-core")
      path()
        .d(M(512, 64), A(448, 448, 0, false, true, 899.979, 736))
        .class("rotating-ring-sector-with-disc-ring")
        .fill(.none)
        .stroke(.currentColor)
        .strokeWidth(128)
    }
    .class(
      stringIsEmpty(`class`)
        ? "rotating-ring-sector-with-disc-view" : "rotating-ring-sector-with-disc-view \(`class`)"
    )
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
    .role("progressbar")
    .ariaHidden(ariaHidden)
    .ariaLabel(ariaHidden ? nil : ariaLabel)
    .style {
      width(size)
      height(size)
      selector("&") { display(.inlineBlock); flexShrink(0) }
      child(".rotating-ring-sector-with-disc-ring") {
        transformOrigin(perc(50), perc(50))
        animation("rotating-ring-sector-with-disc-spin", animationDurationFast, animationTimingFunctionBase, .infinite)
        media(prefersReducedMotion(.reduce)) { animation("none") }
      }
      keyframes("rotating-ring-sector-with-disc-spin") {
        from { transform(rotate(deg(0))) }
        to { transform(rotate(deg(360))) }
      }
    }
  }
}

#if CLIENT
  import WebAPIs

  public enum RotatingRingSectorWithDiscFactory {
    public static func createElement(
      size: CSS.Length = spacing8,
      ariaHidden: Bool = true,
      class: String = ""
    ) -> DOM.Element {
      StyleSheetLoader.ensure("rotating-ring-sector-with-disc-view")
      let wrapper = document.createElement(.span)
      wrapper.innerHTML = RotatingRingSectorWithDiscView(
        size: size, ariaHidden: ariaHidden, class: `class`
      ).render()
      if let leaf = wrapper.firstElementChild { return leaf }
      return wrapper
    }
  }
#endif
