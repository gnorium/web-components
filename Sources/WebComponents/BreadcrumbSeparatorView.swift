import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

// Both SERVER and CLIENT: client code draws BreadcrumbLabelView, which holds
// one. Build() must stay embedded-safe (stringIsEmpty, not String.isEmpty).

/// The chevron between two steps of a trail: BreadcrumbView's, and anywhere
/// else a thing is shown under what it belongs to (BreadcrumbLabelView). One
/// view, so every trail draws the same icon at the same size and colour.
public struct BreadcrumbSeparatorView: HTMLContent {
  let `class`: String

  public init(class: String = "") {
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    span {
      NextIconView(width: px(8), height: px(8))
    }
    .class(stringIsEmpty(`class`) ? "breadcrumb-separator-view" : "breadcrumb-separator-view \(`class`)")
    .ariaHidden(true)
    .style {
      selector("&") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        flexShrink(0)
        verticalAlign(.middle)
        lineHeight(lineHeightContent)
        color(colorBase)
        userSelect(.none)
      }
    }
  }
}
