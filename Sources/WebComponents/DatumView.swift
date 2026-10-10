import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// One labeled fact, shown as a read-only field shows its value: the label
/// above, the value in the field's box.
///
/// It looks like a field because it sits among fields and is read the same
/// way, but it is not one. Nothing can be typed into it and nothing submits
/// it, so it has no control: the value is ordinary content—text, a link
/// that clicks, a date—and a screen reader reads it as text rather than
/// announcing a read-only input. The label is not a `<label>`, since there
/// is no control for it to label.
///
/// One line, like the input it looks like: a long value (an id, a byline)
/// never widens the page. It fades at each edge that hides some of it and
/// scrolls sideways, and on touch a tap wraps it whole (`fadeOverflow`).
///
/// Its box is the read-only field's gray: a fact shown to the reader. A
/// `sent` datum—one the model itself produced, a tool call's argument—sits
/// on white instead: white is what the model sends out, gray what it is
/// given (user, 2026-10-10), and the datum carries that as `data-sent`.
///
/// Built on the server and in the client alike (a live trace card's detail
/// shows its size as one).
public struct DatumView: HTMLContent {
  let label: String
  /// What stands after the label: a record page's reference marks.
  let labelMarks: [DOM.Node]
  let value: [DOM.Node]
  let `class`: String
  /// Its element's id, where something links to it (a revision's
  /// "Changed" line); none when empty.
  let id: String
  /// Whether the value is something sent out (white) rather than given
  /// (gray).
  let sent: Bool

  public init(
    _ label: String, labelMarks: [DOM.Node] = [], class: String = "", id: String = "", sent: Bool = false,
    @HTMLBuilder value: () -> [DOM.Node]
  ) {
    self.label = label
    self.labelMarks = labelMarks
    self.class = `class`
    self.id = id
    self.sent = sent
    self.value = value()
  }

  /// The common case: a plain value.
  public init(
    _ label: String, labelMarks: [DOM.Node] = [], value: String, class: String = "", id: String = "", sent: Bool = false
  ) {
    self.init(label, labelMarks: labelMarks, class: `class`, id: id, sent: sent) { value }
  }

  public func build() -> DOM.Node {
    let view = div {
      div {
        label
        labelMarks
      }
      .class("datum-label")
      div {
        div { value }
          .class("datum-text")
          .data("edge-fade", "expand")
      }
      .class("datum-value")
    }
    .class(stringIsEmpty(`class`) ? "datum-view" : "datum-view \(`class`)")
    let tagged = sent ? view.data("sent", "true") : view
    return (stringIsEmpty(id) ? tagged : tagged.id(id))
    .style {
      selector("&") {
        display(.flex)
        flexDirection(.column)
        gap(spacing4)
        minWidth(0)
        backgroundColor(.transparent)
      }
      // The field label's type, as TextInputView sets it.
      // A row, its marks 4px after its words, as a field's label row.
      descendant(".datum-label") {
        backgroundColor(.transparent)
        display(.flex)
        alignItems(.center)
        gap(spacing4)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightSemiBold)
        color(colorBase)
      }
      // A read-only field's box, to the pixel: its inset of 8 on every
      // side, its line, border, corner and ground.
      descendant(".datum-value") {
        display(.flex)
        alignItems(.center)
        padding(spacing8)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        lineHeight(lineHeightSmall22)
        color(colorBase)
        // Read-only values share the disabled field ground at every depth.
        backgroundColor(backgroundColorDisabled)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        minWidth(0)
      }
      // What was sent out stands on white, the page's own ground.
      selector("&[data-sent='true'] > .datum-value") {
        backgroundColor(backgroundColorBase)
      }
      // The value's one line, inside the box so that the fades take its
      // letters and not the box's border or ground: past the box it fades
      // and scrolls sideways, and a tap on touch wraps it (EdgeFade.swift).
      // A row, as the box was, so a value of several parts sits in one line.
      descendant(".datum-text") {
        display(.flex)
        flexWrap(.nowrap)
        alignItems(.center)
        flex(1)
        minWidth(0)
      }
      fadeOverflow("& .datum-text")
    }
    .build()
  }
}
