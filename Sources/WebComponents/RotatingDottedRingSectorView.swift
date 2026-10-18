import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// A rotating 120° sector of the dotted ring (user, 2026-10-18): 5 dots from
/// the top, clockwise. Every wait that is not a page's wording—a running
/// arbitration, prompts, images, a translation layer, a gloss—turns it.
/// Drawn as `DottedRingView` is, on the same circle.
public struct RotatingDottedRingSectorView: HTMLContent {
  let size: CSS.Length
  let ariaHidden: Bool
  let ariaLabel: String
  let `class`: String

  public init(
    size: CSS.Length = sizeIconSmall,
    ariaHidden: Bool = false,
    ariaLabel: String = "Loading",
    class: String = ""
  ) {
    self.size = size
    self.ariaHidden = ariaHidden
    self.ariaLabel = ariaLabel
    self.class = `class`
  }

  public func build() -> DOM.Node {
    let radius = DottedRingView.radius
    svg {
      path()
        // A third of the ring: from the top, 120° clockwise. Its length is
        // four steps, so the 5 dots fall on both ends and between.
        .d(
          M(512, 512 - radius),
          A(radius, radius, 0, false, true, 512 + radius * 0.8660254037844386, 512 + radius / 2))
        .class("rotating-dotted-ring-sector-shape")
        .fill(.none)
        .stroke(.currentColor)
        .strokeWidth(iconStrokeWidth)
        .strokeLinecap(.round)
        .strokeDasharray(DottedRingView.dasharray)
        .strokeDashoffset(DottedRingView.dashoffset)
    }
    .class(
      stringIsEmpty(`class`)
        ? "rotating-dotted-ring-sector-view" : "rotating-dotted-ring-sector-view \(`class`)"
    )
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .role("progressbar")
    .ariaHidden(ariaHidden)
    .ariaLabel(ariaHidden ? nil : ariaLabel)
    .style {
      width(size)
      height(size)
      selector("&") { display(.inlineBlock); flexShrink(0); color(colorBlue) }  // Progress is always blue (user, 2026-10-11).
      child(".rotating-dotted-ring-sector-shape") {
        transformOrigin(perc(50), perc(50))
        animation("rotating-dotted-ring-sector-spin", animationDurationFast, animationTimingFunctionBase, .infinite)
        media(prefersReducedMotion(.reduce)) { animation("none") }
      }
      keyframes("rotating-dotted-ring-sector-spin") {
        from { transform(rotate(deg(0))) }
        to { transform(rotate(deg(360))) }
      }
    }
  }
}

#if CLIENT
  import WebAPIs

  public enum RotatingDottedRingSectorFactory {
    public static func createElement(
      size: CSS.Length = sizeIconSmall,
      ariaHidden: Bool = true,
      class: String = ""
    ) -> DOM.Element {
      StyleSheetLoader.ensure("rotating-dotted-ring-sector-view")
      let wrapper = document.createElement(.span)
      wrapper.innerHTML = RotatingDottedRingSectorView(
        size: size, ariaHidden: ariaHidden, class: `class`
      ).render()
      if let leaf = wrapper.firstElementChild { return leaf }
      return wrapper
    }
  }
#endif
