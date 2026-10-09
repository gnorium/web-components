import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// A sweeping 120° disc sector, representing explication in progress.
public struct RotatingSectorView: HTMLContent {
  let size: CSS.Length
  let showLabel: Bool
  let ariaHidden: Bool
  let ariaLabel: String?
  let content: [DOM.Node]
  let `class`: String

  public init(
    size: CSS.Length = spacing8,
    showLabel: Bool = false,
    ariaHidden: Bool = false,
    ariaLabel: String? = nil,
    class: String = "",
    @HTMLBuilder content: () -> [DOM.Node] = { [] }
  ) {
    self.size = size
    self.showLabel = showLabel
    self.ariaHidden = ariaHidden
    self.ariaLabel = ariaLabel
    self.content = content()
    self.class = `class`
  }

  public func build() -> DOM.Node {
    let labeled = showLabel && !content.isEmpty
    let rootClass =
      stringIsEmpty(`class`) ? "rotating-sector-view" : "rotating-sector-view \(`class`)"
    let sector = svg {
      path()
        .d(M(512, 512), L(512, 0), A(512, 512, 0, false, true, 955.405, 768), Z())
        .class("rotating-sector-shape")
    }
    .class(labeled ? "rotating-sector-mark" : rootClass)
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
    // Per-instance sizes stay inline; the shared stylesheet cannot capture one size.
    .style { width(size); height(size) }

    if labeled {
      return div {
        sector.ariaHidden(true)
        span { content }.class("rotating-sector-label")
      }
      .class(rootClass)
      .role("progressbar")
      .ariaHidden(ariaHidden)
      .ariaLabel(ariaHidden ? nil : ariaLabel)
      .style { Self.styles() }
    }
    return sector
      .role("progressbar")
      .ariaHidden(ariaHidden)
      .ariaLabel(ariaHidden ? nil : (ariaLabel ?? "Explication running"))
      .style { Self.styles() }
  }

  @CSSBuilder private static func styles() -> [CSSOM.CSSRule] {
    selector("&") {
      display(.inlineFlex)
      alignItems(.center)
      gap(spacing8)
      flexShrink(0)
    }
    descendant(".rotating-sector-mark") { display(.block); flexShrink(0) }
    descendant(".rotating-sector-label") {
      fontFamily(typographyFontSans)
      fontSize(fontSizeMedium16)
      fontWeight(fontWeightNormal)
      lineHeight(lineHeightSmall22)
      color(colorSubtle)
    }
    descendant(".rotating-sector-shape") {
      transformOrigin(perc(50), perc(50))
      animation("rotating-sector-spin", animationDurationFast, animationTimingFunctionBase, .infinite)
      media(prefersReducedMotion(.reduce)) { animation("none") }
    }
    keyframes("rotating-sector-spin") {
      from { transform(rotate(deg(0))) }
      to { transform(rotate(deg(360))) }
    }
  }
}

#if CLIENT
  import WebAPIs

  public enum RotatingSectorFactory {
    public static func createElement(
      size: CSS.Length = spacing8,
      ariaHidden: Bool = true,
      class: String = ""
    ) -> DOM.Element {
      StyleSheetLoader.ensure("rotating-sector-view")
      let wrapper = document.createElement(.span)
      wrapper.innerHTML = RotatingSectorView(
        size: size, ariaHidden: ariaHidden, class: `class`
      ).render()
      if let leaf = wrapper.firstElementChild { return leaf }
      return wrapper
    }
  }
#endif
