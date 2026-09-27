import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

// Both SERVER and CLIENT: DropdownView draws it on the server, the search
// menus draw it on the client from their JSON. Build() must stay
// embedded-safe (stringIsEmpty, not String.isEmpty).

/// A name under what it belongs to, as a breadcrumb reads: "English › computer".
///
/// The context comes first, plain and subtle (BreadcrumbView's trail colour),
/// then BreadcrumbView's own chevron, then the name, which keeps whatever
/// weight and colour its container gives it (link blue in the search menu,
/// semibold in a dropdown). Inline flow, as BreadcrumbView's trail is: a long
/// name wraps as running text and uses the whole width, where a column after
/// the chevron was left a narrow strip on a phone. The chevron never starts a
/// line: a no-break space holds it to the context.
public struct BreadcrumbLabelView: HTMLContent {
  let context: String
  let text: String
  let `class`: String

  public init(context: String, text: String, class: String = "") {
    self.context = context
    self.text = text
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    // The spaces are the spacing (inline flow has no gap), and keep the text
    // readable as text ("English computer", not "Englishcomputer") for
    // copying and for a screen reader, which skips the chevron.
    span {
      span { context }
        .class("breadcrumb-label-context")
      "\u{00A0}"
      BreadcrumbSeparatorView()
      " "
      span { text }
        .class("breadcrumb-label-text")
    }
    .class(stringIsEmpty(`class`) ? "breadcrumb-label-view" : "breadcrumb-label-view \(`class`)")
    .style {
      selector("&") {
        display(.inline)
        overflowWrap(.breakWord)
      }
      descendant(".breadcrumb-label-context") {
        fontWeight(fontWeightNormal)
        color(colorSubtle)
      }
    }
  }
}
