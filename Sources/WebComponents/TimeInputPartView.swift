import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

// Built on both sides, inside TimeInputView: embedded-safe.

/// One time in a time input's popover: its label (Time start, Time end),
/// with its tooltip as a form's labels have, over its hours and minutes,
/// each a listbox column that scrolls.
public struct TimeInputPartView: HTMLContent {
  /// "start" or "end".
  let part: String
  /// "Time start", "Time end"; empty for a single time.
  let caption: String
  /// "Start time of the range."
  let tooltip: String?
  let time: TimeOfDay?

  public init(part: String, caption: String, tooltip: String?, time: TimeOfDay?) {
    self.part = part
    self.caption = caption
    self.tooltip = tooltip
    self.time = time
  }

  public func build() -> DOM.Node {
    let hasCaption = !stringIsEmpty(caption)
    let prefix = hasCaption ? "\(caption) " : ""
    return div {
      if hasCaption {
        LabelView(labelFontSize: fontSizeSmall14, tooltip: tooltip, class: "time-input-part-caption") { caption }
      }
      div {
        column(unit: "hour", label: "\(prefix)hours", count: 24, selected: time?.hour)
        span { ":" }
          .class("time-input-separator")
          .ariaHidden(true)
        column(unit: "minute", label: "\(prefix)minutes", count: 60, selected: time?.minute)
      }
      .class("time-input-columns")
    }
    .class("time-input-part-view")
    .data("part", part)
    .style {
      selector("&") {
        display(.flex)
        flexDirection(.column)
        gap(spacing4)
        flex(1)
        minWidth(0)
      }
      descendant(".time-input-columns") {
        display(.flex)
        alignItems(.flexStart)
        gap(spacing4)
      }
      descendant(".time-input-separator") {
        alignSelf(.center)
        fontWeight(fontWeightSemiBold)
        color(colorSubtle)
      }
      // Five rows show at once; the rest scroll, a finger's 40px each.
      descendant(".time-input-column") {
        flex(1)
        minWidth(0)
        maxHeight(calc("\(minSizeInteractiveTouch.value) * 5"))
        overflowY(.auto)
        margin(0)
        padding(0)
        listStyle(.none)
        outline(.none)
      }
      descendant(".time-input-option") {
        display(.flex)
        alignItems(.center)
        justifyContent(.center)
        blockSize(minSizeInteractiveTouch)
        borderRadius(borderRadiusBase)
        fontSize(fontSizeSmall14)
        fontVariantNumeric(.tabularNums)
        color(colorBase)
        cursor(.pointer)
        outline(.none)
        userSelect(.none)
        transition("background-color 0.1s ease, color 0.1s ease")
      }
      descendant(".time-input-option:hover") {
        backgroundColor(backgroundColorInteractiveSubtleHover)
      }
      descendant(".time-input-option[aria-selected='true']") {
        backgroundColor(backgroundColorBlue).important()
        color(colorInvertedFixed).important()
        fontWeight(fontWeightSemiBold)
      }
      // The ring every control wears for keyboard focus.
      descendant(".time-input-option:focus-visible") {
        outline(borderWidthThick, .solid, borderColorBlueFocus)
        outlineOffset(calc("-\(borderWidthThick.value)"))
      }
    }
  }

  /// A column of hours or minutes: one option takes Tab, the selected one
  /// or else the first (roving tabindex).
  @HTMLBuilder
  private func column(unit: String, label: String, count: Int, selected: Int?) -> [DOM.Node] {
    let focus = selected ?? 0
    ul {
      for value in 0..<count {
        let isSelected = selected.map { $0 == value } ?? false
        li { TimeOfDay.twoDigits(value) }
          .class("time-input-option")
          .role(.option)
          .tabindex(value == focus ? 0 : -1)
          .data("value", "\(value)")
          .ariaSelected(isSelected)
      }
    }
    .class("time-input-column")
    .role(.listbox)
    .ariaLabel(label)
    .data("unit", unit)
  }
}
