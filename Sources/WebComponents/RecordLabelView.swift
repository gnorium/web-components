import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

// Both SERVER and CLIENT: the search menu draws it on the client from its
// JSON, a gloss's heading on the server. Build() must stay embedded-safe
// (stringIsEmpty, not String.isEmpty).

/// A record as the records search menu offers one, in two rows: its
/// language › its title (`BreadcrumbLabelView`), then what it is, small and
/// subtle—its class, a work's voices and type—with a homograph's number
/// raised after it. "Middle English › anker", "Noun".
///
/// With a `url` the title is a link to the record, in the link's colors
/// (a gloss's heading); without, it takes its container's (a search menu
/// row, which is the link itself). With no `context`, the title alone: a
/// term with no record.
public struct RecordLabelView: HTMLContent {
  let context: String
  let text: String
  let meta: String
  let homograph: Int
  let url: String
  let `class`: String

  public init(context: String, text: String, meta: String, homograph: Int = 0, url: String = "", class: String = "") {
    self.context = context
    self.text = text
    self.meta = meta
    self.homograph = homograph
    self.url = url
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    span {
      if stringIsEmpty(url) {
        span {
          if stringIsEmpty(context) { text } else { BreadcrumbLabelView(context: context, text: text) }
        }
        .class("record-label-title")
      } else {
        LinkView(url: url, class: "record-label-title") {
          if stringIsEmpty(context) { text } else { BreadcrumbLabelView(context: context, text: text) }
        }
      }
      span {
        meta
        if homograph > 1 {
          sup { "\(homograph)" }
            .class("record-label-sup")
        }
      }
      .class("record-label-meta")
    }
    .class(stringIsEmpty(`class`) ? "record-label-view" : "record-label-view \(`class`)")
    .style {
      selector("&") {
        display(.flex)
        flexDirection(.column)
        minWidth(px(0))
        fontFamily(typographyFontSans)
        lineHeight(lineHeightSmall22)
      }
      descendant(".record-label-title") {
        fontSize(fontSizeSmall14)
        fontWeight(fontWeightNormal)
        overflowWrap(.breakWord)
      }
      descendant(".record-label-meta") {
        fontSize(fontSizeXSmall12)
        fontWeight(fontWeightNormal)
        color(colorSubtle)
      }
      // Inside the meta line: its size and color, raised.
      descendant(".record-label-sup") {
        fontSize(perc(75))
      }
    }
  }
}
