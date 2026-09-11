import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// Animated 120° conic sector — indeterminate activity mark (leaf).
/// Available on SERVER + CLIENT so RotatingSectorFactory can render without replicas.
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
    let hasContent = !content.isEmpty
    let rootClass =
      stringIsEmpty(`class`) ? "rotating-sector-view" : "rotating-sector-view \(`class`)"

    let sector = span {}
      .class(hasContent && showLabel ? "rotating-sector" : rootClass)
      .style {
        selector("&") {
          display(.inlineBlock)
          width(size)
          height(size)
          borderRadius(borderRadiusCircle)
          background(
            conicGradient(
              (colorBlue, deg(0)),
              (colorBlue, deg(120)),
              (backgroundColorTransparent, deg(120))
            )
          )
          animation("rotating-sector-spin", s(0.8), .linear, .infinite)
          flexShrink(0)
        }
        keyframes("rotating-sector-spin") {
          from { transform(rotate(deg(0))) }
          to { transform(rotate(deg(360))) }
        }
      }

    if !(hasContent && showLabel) {
      var leaf = sector
        .role("progressbar")
        .ariaHidden(ariaHidden)
        .ariaValueMin(0)
        .ariaValueMax(100)
      let labelValue = ariaLabel ?? "Loading"
      if !ariaHidden {
        leaf = leaf.ariaLabel(labelValue)
      }
      return leaf
    }

    var wrapper = div {
      sector
      span {
        content
      }
      .class("rotating-sector-label")
    }
    .class(rootClass)
    .role("progressbar")
    .ariaHidden(ariaHidden)
    .ariaValueMin(0)
    .ariaValueMax(100)

    if let labelValue = ariaLabel {
      wrapper = wrapper.ariaLabel(labelValue)
    }

    return
      wrapper
      .style {
        selector("&") {
          display(.inlineFlex)
          alignItems(.center)
          gap(spacing8)
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          fontWeight(fontWeightNormal)
          lineHeight(lineHeightSmall22)
          color(colorSubtle)
        }
        descendant(".rotating-sector") {
          display(.inlineBlock)
          width(size)
          height(size)
          borderRadius(borderRadiusCircle)
          background(
            conicGradient(
              (colorBlue, deg(0)),
              (colorBlue, deg(120)),
              (backgroundColorTransparent, deg(120))
            )
          )
          animation("rotating-sector-spin", s(0.8), .linear, .infinite)
          flexShrink(0)
        }
        descendant(".rotating-sector-label") { display(.inline) }
        keyframes("rotating-sector-spin") {
          from { transform(rotate(deg(0))) }
          to { transform(rotate(deg(360))) }
        }
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
      let wrapper = document.createElement(.span)
      let view = RotatingSectorView(
        size: size,
        ariaHidden: ariaHidden,
        class: `class`
      )
      wrapper.innerHTML = renderHTML { view.render() }
      if let leaf = wrapper.firstElementChild {
        return leaf
      }
      return wrapper
    }
  }
#endif
