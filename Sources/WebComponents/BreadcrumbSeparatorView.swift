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
/// view, so every trail draws the same icon at the same size and color.
public struct BreadcrumbSeparatorView: HTMLContent {
  let `class`: String

  public init(class: String = "") {
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    span {
      // Punctuation between words, not a mark beside them: the text's font
      // size, never its line height (user, 2026-10-21).
      ChevronRightIconView(size: fontSizeMedium16)
    }
    .class(stringIsEmpty(`class`) ? "breadcrumb-separator-view" : "breadcrumb-separator-view \(`class`)")
    .ariaHidden(true)
    .style {
      // Centered on the line it stands in (user, 2026-11-03): a box one
      // line high (its text's line height, inherited) from the line's top,
      // the chevron in its middle. `middle` set it on the lowercase
      // letters' middle, 2px under the line's.
      selector("&") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        flexShrink(0)
        verticalAlign(.top)
        height(lh(1))
        color(colorBase)
        userSelect(.none)
      }
    }
  }
}
