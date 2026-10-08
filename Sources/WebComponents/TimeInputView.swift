import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

// TimeInputView builds on both sides so TimeInputFactory can draw one on the
// client (the filter bar adds fields there). build() stays embedded-safe:
// stringIsEmpty/stringEquals, `if let` rather than `== nil` on a String?.

/// A field that holds a time of day on a 12-hour clock, as the tables' "at"
/// columns read ("5:40 PM"), picked from three scrolling columns—hour 1–12,
/// minutes, AM/PM—in the date picker's popover, field and footer
/// (DatePickerView), so the two read as one family.
///
/// The field shows the time ("9:30 AM"); a hidden input carries it as `HH:MM`
/// (24-hour) under `name`. A range input (`range: true`) holds a span of the
/// day instead, picked in the reader's clock and carried with the reader's
/// IANA zone (`TimeRangeValue`, `09:00..17:30[Asia/Kolkata]`); one set in
/// another zone reads in the reader's clock with its own span after it
/// ("11:30 PM–8:00 AM (9:00 AM–5:30 PM Kolkata time)"): Time start and Time
/// end—as a year range's are Year start and Year end (FormDateView)—each its
/// columns, side by side in one popover, as a date range is one popover.
/// Either end may stay open. The field is read-only and asks for no
/// keyboard: a tap opens the columns, and a tap on an hour or a minute sets
/// it. With the keyboard, Enter, Space or ↓ opens them; ↑ and ↓ move through
/// a column and set as they go, Home and End go to its ends, Tab goes to the
/// next column, Esc closes, Backspace in the field clears it.
public struct TimeInputView: HTMLContent {
  let id: String
  let name: String
  /// `HH:MM`, or for a range `HH:MM..HH:MM[Zone/Name]`; empty for none.
  let value: String
  let placeholder: String
  let range: Bool
  let labelText: String
  let fullWidth: Bool
  let disabled: Bool
  let `class`: String
  /// The id of the form it submits with, when it sits outside that form.
  let form: String?

  public init(
    id: String,
    name: String,
    value: String = "",
    placeholder: String = "Select a time",
    range: Bool = false,
    label: String = "",
    fullWidth: Bool = true,
    disabled: Bool = false,
    class: String = "",
    form: String? = nil
  ) {
    self.id = id
    self.name = name
    self.value = value
    self.placeholder = placeholder
    self.range = range
    self.labelText = label
    self.fullWidth = fullWidth
    self.disabled = disabled
    self.`class` = `class`
    self.form = form
  }

  /// The value in force, in the reader's clock: one time, or a span.
  static func parts(_ value: String, range: Bool) -> (start: TimeOfDay?, end: TimeOfDay?) {
    if range {
      guard let span = TimeRangeValue.parse(value) else { return (nil, nil) }
      return span.local
    }
    return (TimeOfDay.parse(value), nil)
  }

  /// The value a form submits for times in the reader's clock: a span
  /// with the reader's zone, a single time as it is.
  static func param(start: TimeOfDay?, end: TimeOfDay?, range: Bool) -> String {
    guard range else { return start?.text ?? "" }
    if case .none = start, case .none = end { return "" }
    return TimeRangeValue.fromLocal(start: start, end: end).param
  }

  /// What the field shows for times picked in the reader's clock: "9:00
  /// AM–5:30 PM", "Since 9:00 AM", "9:30 AM".
  static func fieldText(start: TimeOfDay?, end: TimeOfDay?, range: Bool) -> String {
    guard range else { return start?.text12 ?? "" }
    return TimeRangeValue.words(start, end)
  }

  /// What the field shows for a value as given: a span set in another zone
  /// names that zone's own span too (TimeRangeValue.label).
  static func valueText(_ value: String, range: Bool) -> String {
    guard range else { return TimeOfDay.parse(value)?.text12 ?? "" }
    return TimeRangeValue.parse(value)?.label ?? ""
  }

  public func build() -> DOM.Node {
    let (start, end) = Self.parts(value, range: range)
    // The value as given—a span keeps the zone it was set in until the
    // reader picks anew.
    let param = range ? TimeRangeValue.parse(value)?.param ?? "" : TimeOfDay.parse(value)?.text ?? ""
    let rootClass = stringIsEmpty(`class`)
      ? "time-input-view\(fullWidth ? " time-input-full-width" : "")"
      : "time-input-view\(fullWidth ? " time-input-full-width" : "") \(`class`)"

    var valueInput = input()
      .type(.hidden)
      .name(name)
      .value(param)
      .class("time-input-value")
    if let form {
      valueInput = valueInput.form(form)
    }

    return div {
      valueInput

      TextInputView(
        id: id,
        name: "",
        placeholder: placeholder,
        value: Self.valueText(value, range: range),
        disabled: disabled,
        readonly: true,
        label: labelText,
        fullWidth: fullWidth,
        class: "time-input-field",
        inputMode: HTML.InputMode.none
      )

      ButtonView(
        icon: IconView(icon: { s in ClockIconView(size: s) }, size: sizeIconSmall),
        weight: .plain,
        size: .medium,
        disabled: disabled,
        ariaLabel: range ? "Choose times" : "Choose time",
        class: "time-input-toggle"
      )

      PopoverView(
        id: "\(id)-popover",
        placement: .bottomStart,
        showsArrow: false,
        ariaLabel: range ? "Choose times" : "Choose time",
        class: "time-input-popover",
        body: {
          div {
            if range {
              TimeInputPartView(
                part: "start", caption: "Time start", tooltip: "Start time of the range.", time: start)
              TimeInputPartView(part: "end", caption: "Time end", tooltip: "End time of the range.", time: end)
            } else {
              TimeInputPartView(part: "start", caption: "", tooltip: nil, time: start)
            }
          }
          .class("time-input-parts")
        },
        footer: {
          div {
            ButtonView(
              label: "Reset",
              buttonColor: .blue,
              weight: .plain,
              size: .medium,
              class: "time-input-reset",
              labelFontWeight: fontWeightNormal
            )
            ButtonView(
              label: "Done",
              buttonColor: .blue,
              weight: .plain,
              size: .medium,
              class: "time-input-done"
            )
          }
          .class("time-input-footer")
        }
      )
    }
    .class(rootClass)
    .data("range", range)
    .data("open", false)
    .style {
      selector("&") {
        position(.relative)
        display(.inlineBlock)
        fontFamily(typographyFontSans)
      }
      selector("&.time-input-full-width") { width(perc(100)) }

      // The field is the date picker's: a button in an input's clothes, 40px,
      // no caret, the base background, room at the end for the clock.
      descendant(".time-input-field .text-input-input") {
        height(minSizeInteractiveTouch).important()
        minHeight(minSizeInteractiveTouch).important()
        paddingBlock(0).important()
        paddingInlineEnd(calc("\(spacing8.value) + \(size32.value) + \(spacing4.value)")).important()
        backgroundColor(backgroundColorBase).important()
        cursor(.pointer).important()
        userSelect(.none)
        fontVariantNumeric(.tabularNums)
      }
      descendant(".time-input-field.text-input-disabled .text-input-input") {
        backgroundColor(backgroundColorDisabled).important()
        cursor(cursorNotAllowed).important()
      }
      descendant(".time-input-field .text-input-input:focus") {
        borderColor(borderColorBlue).important()
        outline(.none).important()
        boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
      }
      selector("&[data-open='true'] .time-input-field .text-input-input") {
        borderColor(borderColorBlue).important()
        boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
      }
      descendant(".time-input-toggle") {
        position(.absolute)
        insetBlockEnd(spacing4)
        insetInlineEnd(spacing8)
        width(size32).important()
        height(size32).important()
        minWidth(size32).important()
        minHeight(size32).important()
        padding(0).important()
        backgroundColor(backgroundColorTransparent).important()
        borderColor(borderColorTransparent).important()
      }

      // As wide as the field, like the date picker's calendar; border only.
      descendant(".time-input-popover") {
        minWidth(calc("min(\(minSizeInteractiveTouch.value) * 5 + \(spacing8.value) * 3 + \(borderWidthBase.value) * 2, 100vw - \(spacing16.value) * 2)")).important()
        maxWidth(.none).important()
        boxShadow(.none).important()
        boxSizing(.borderBox)
      }
      selector("&[data-range='true'] .time-input-popover") {
        minWidth(calc("min(\(minSizeInteractiveTouch.value) * 10 + \(spacing8.value) * 6 + \(spacing16.value) + \(borderWidthBase.value) * 2, 100vw - \(spacing16.value) * 2)")).important()
      }
      descendant(".time-input-popover[data-placement^='bottom']") {
        top(calc("100% + \(spacing4.value)"))
      }
      descendant(".time-input-popover[data-placement^='top']") {
        bottom(calc("100% + \(spacing4.value)"))
      }
      descendant(".time-input-popover[data-placement$='start']") {
        insetInlineStart(0)
        insetInlineEnd(0)
      }
      descendant(".time-input-popover[data-placement$='end']") {
        insetInlineStart(.auto)
        insetInlineEnd(0)
      }
      descendant(".time-input-popover .popover-body") {
        padding(spacing8).important()
      }
      descendant(".time-input-popover .popover-footer") {
        padding(spacing4, spacing8).important()
      }
      descendant(".time-input-parts") {
        display(.flex)
        gap(spacing16)
      }
      descendant(".time-input-footer") {
        display(.flex)
        flex(1)
        justifyContent(.spaceBetween)
        alignItems(.center)
        gap(spacing8)
      }
    }
  }
}

#if CLIENT
  import WebAPIs

  private final class TimeInputInstance: @unchecked Sendable {
    private let root: DOM.Element
    private let valueInput: HTML.HTMLInputElement?
    private let field: HTML.HTMLInputElement?
    private let toggle: DOM.Element?
    private let popover: DOM.Element?
    private let resetButton: DOM.Element?
    private let doneButton: DOM.Element?
    private let isRange: Bool
    private var start: TimeOfDay?
    private var end: TimeOfDay?
    private var isOpen = false

    init(root: DOM.Element) {
      self.root = root
      valueInput = root.querySelector(".time-input-value") as? HTML.HTMLInputElement
      field = root.querySelector(".time-input-field .text-input-input") as? HTML.HTMLInputElement
      toggle = root.querySelector(".time-input-toggle")
      popover = root.querySelector(".time-input-popover")
      resetButton = root.querySelector(".time-input-reset")
      doneButton = root.querySelector(".time-input-done")
      isRange = stringEquals(root.getAttribute(data("range")) ?? "", "true")
      let parts = TimeInputView.parts(valueInput?.value ?? "", range: isRange)
      start = parts.start
      end = parts.end
      // The server drew the times in the zone the request named; the
      // browser's is the reader's own, so they are shown again in it.
      field?.value = TimeInputView.valueText(valueInput?.value ?? "", range: isRange)

      root.setAttribute(data("hydrated"), true)
      if let field {
        field.setAttribute("aria-haspopup", "dialog")
        field.setAttribute("aria-expanded", "false")
        if let popover, let popoverID = popover.getAttribute("id") {
          field.setAttribute("aria-controls", popoverID)
        }
      }
      // The field is the keyboard's way in; the clock is the pointer's.
      toggle?.setAttribute("tabindex", "-1")
      bindEvents()
    }

    // MARK: - Events

    private func bindEvents() {
      if let field {
        _ = field.addEventListener(.click) { [self] _ in
          if self.isOpen { self.close(returnFocus: false) } else { self.open(fromKeyboard: false) }
        }
        _ = field.addEventListener(.keydown) { [self] event in
          let key = event.key
          if stringEquals(key, "Enter") || stringEquals(key, " ") || stringEquals(key, "ArrowDown") {
            event.preventDefault()
            self.open(fromKeyboard: true)
          } else if stringEquals(key, "Backspace") || stringEquals(key, "Delete") {
            event.preventDefault()
            self.start = nil
            self.end = nil
            self.commit()
          }
        }
      }
      if let toggle {
        _ = toggle.addEventListener(.click) { [self] _ in
          if self.isOpen { self.close(returnFocus: true) } else { self.open(fromKeyboard: false) }
        }
      }
      if let resetButton {
        _ = resetButton.addEventListener(.click) { [self] _ in
          self.start = nil
          self.end = nil
          self.commit()
          self.markAll()
        }
      }
      if let doneButton {
        _ = doneButton.addEventListener(.click) { [self] _ in self.close(returnFocus: true) }
      }
      for column in root.querySelectorAll(".time-input-column") {
        _ = column.addEventListener(.click) { [self] event in
          guard let target = event.target, let option = target.closest(".time-input-option") else { return }
          self.pick(option, in: column, fromKeyboard: false)
        }
        _ = column.addEventListener(.keydown) { [self] event in
          self.handleColumnKey(event, column: column)
        }
      }
      if let popover {
        _ = popover.addEventListener(.keydown) { [self] event in
          let key = event.key
          if stringEquals(key, "Escape") {
            event.preventDefault()
            self.close(returnFocus: true)
          } else if stringEquals(key, "Tab") {
            self.trapTab(event)
          }
        }
      }
      // A tap or click anywhere else closes it, as the date picker's does.
      _ = document.addEventListener(.mousedown) { [self] event in
        guard self.isOpen, let target = event.target else { return }
        if !self.root.contains(target) {
          self.close(returnFocus: false)
        }
      }
    }

    private func handleColumnKey(_ event: Event, column: DOM.Element) {
      let key = event.key
      let options = column.querySelectorAll(".time-input-option")
      guard !options.isEmpty else { return }
      var index = 0
      for (position, option) in options.enumerated() {
        if let tabindex = option.getAttribute("tabindex"), stringEquals(tabindex, "0") { index = position }
      }
      var target: Int?
      if stringEquals(key, "ArrowUp") {
        target = index > 0 ? index - 1 : options.count - 1
      } else if stringEquals(key, "ArrowDown") {
        target = index < options.count - 1 ? index + 1 : 0
      } else if stringEquals(key, "Home") {
        target = 0
      } else if stringEquals(key, "End") {
        target = options.count - 1
      } else if stringEquals(key, "Enter") || stringEquals(key, " ") {
        event.preventDefault()
        pick(options[index], in: column, fromKeyboard: true)
        return
      }
      guard let target else { return }
      event.preventDefault()
      // A time scroller sets as it moves, as the platforms' own do.
      pick(options[target], in: column, fromKeyboard: true)
    }

    /// Tab stays in the popover while it is open, coming round at either end.
    private func trapTab(_ event: Event) {
      guard let popover else { return }
      let focusable = popover.querySelectorAll(
        "button:not([disabled]), [tabindex]:not([tabindex=\"-1\"])")
      guard !focusable.isEmpty, let active = document.activeElement else { return }
      let first = focusable[0]
      let last = focusable[focusable.count - 1]
      if event.shiftKey {
        if active.id == first.id {
          event.preventDefault()
          last.focus()
        }
      } else if active.id == last.id {
        event.preventDefault()
        first.focus()
      }
    }

    // MARK: - State

    /// Sets the hour or minute an option names, in its part; a part first
    /// given its hour starts at :00, first given its minute at 00:.
    private func pick(_ option: DOM.Element, in column: DOM.Element, fromKeyboard: Bool) {
      guard let raw = option.getAttribute(data("value")), let value = parseInt(raw),
        let unit = column.getAttribute(data("unit")),
        let part = column.closest(".time-input-part-view")?.getAttribute(data("part"))
      else { return }
      let isEnd = stringEquals(part, "end")
      let current = isEnd ? end : start
      // A part first given its hour starts at :00 AM; first given its
      // minutes or its half of the day, at 12.
      let hour12 = stringEquals(unit, "hour") ? value : current?.hour12 ?? 12
      let minute = stringEquals(unit, "minute") ? value : current?.minute ?? 0
      let pm = stringEquals(unit, "period") ? value == 1 : current?.isPM ?? false
      let time = TimeOfDay(hour12: hour12, minute: minute, pm: pm)
      if isEnd { end = time } else { start = time }
      commit()
      markAll()
      option.focus(DOM.FocusOptions(preventScroll: true, focusVisible: fromKeyboard))
      option.scrollIntoView(CSSOM.ScrollIntoViewOptions(block: .nearest))
    }

    /// The value and the field, from the times in force.
    private func commit() {
      valueInput?.value = TimeInputView.param(start: start, end: end, range: isRange)
      field?.value = TimeInputView.fieldText(start: start, end: end, range: isRange)
      valueInput?.dispatchEvent(.input)
      valueInput?.dispatchEvent(.change)
    }

    /// Each column's selected option, and its Tab stop.
    private func markAll() {
      for column in root.querySelectorAll(".time-input-column") {
        guard let unit = column.getAttribute(data("unit")),
          let part = column.closest(".time-input-part-view")?.getAttribute(data("part"))
        else { continue }
        let time = stringEquals(part, "end") ? end : start
        let selected: Int? = time.map { time in
          stringEquals(unit, "hour") ? time.hour12 : stringEquals(unit, "minute") ? time.minute : time.isPM ? 1 : 0
        }
        let options = column.querySelectorAll(".time-input-option")
        var focus = 0
        for (index, option) in options.enumerated() {
          let value = parseInt(option.getAttribute(data("value")) ?? "")
          let isSelected = selected.map { selected in value.map { $0 == selected } ?? false } ?? false
          if isSelected { focus = index }
          option.setAttribute("aria-selected", isSelected ? "true" : "false")
        }
        for (index, option) in options.enumerated() {
          option.setAttribute("tabindex", index == focus ? "0" : "-1")
        }
      }
    }

    private func open(fromKeyboard: Bool) {
      guard let popover else { return }
      if let _ = field?.getAttribute("disabled") { return }
      markAll()
      isOpen = true
      popover.setAttribute(data("open"), true)
      root.setAttribute(data("open"), true)
      field?.setAttribute("aria-expanded", "true")
      position()
      // Each column brought round to its time.
      for column in root.querySelectorAll(".time-input-column") {
        column.querySelector("[tabindex=\"0\"]")?.scrollIntoView(CSSOM.ScrollIntoViewOptions(block: .nearest))
      }
      root.querySelector(".time-input-column [tabindex=\"0\"]")?
        .focus(DOM.FocusOptions(preventScroll: true, focusVisible: fromKeyboard))
    }

    private func close(returnFocus: Bool) {
      guard isOpen else { return }
      isOpen = false
      popover?.setAttribute(data("open"), false)
      root.setAttribute(data("open"), false)
      field?.setAttribute("aria-expanded", "false")
      popover?.style.setProperty("translate", "")
      if returnFocus {
        field?.focus(DOM.FocusOptions(preventScroll: true))
      }
    }

    // MARK: - Placement

    private func isRightToLeft() -> Bool {
      guard let holder = root.closest("[dir]"), let dir = holder.getAttribute("dir") else { return false }
      return stringEquals(dir, "rtl")
    }

    /// As the date picker's: under the field unless only above has room;
    /// from the start edge unless that runs off screen and the end does not;
    /// nudged back on screen when neither fits.
    private func position() {
      guard let popover else { return }
      popover.setAttribute(data("placement"), "bottom-start")
      popover.style.setProperty("translate", "")
      guard let anchor = root.getBoundingClientRect(),
        let fieldRect = field?.getBoundingClientRect(),
        let rect = popover.getBoundingClientRect()
      else { return }
      let margin = 8.0
      // The page's width without its scrollbar: innerWidth counts the bar,
      // and a popover sized to it ran under it, off a phone's edge.
      let viewportWidth = document.querySelector("html")?.getBoundingClientRect()?.width ?? window.innerWidth
      let viewportHeight = window.innerHeight
      let roomBelow = viewportHeight - fieldRect.bottom
      let roomAbove = anchor.top
      // Over the field only when it fits there whole: one taller than both
      // rooms opens below, where the page scrolls on to the rest of it,
      // never off the top.
      let vertical = roomBelow < rect.height + margin && roomAbove >= rect.height + margin ? "top" : "bottom"

      let rtl = isRightToLeft()
      let startFits = rtl ? anchor.right - rect.width >= margin : anchor.left + rect.width <= viewportWidth - margin
      let endFits = rtl ? anchor.left + rect.width <= viewportWidth - margin : anchor.right - rect.width >= margin
      let horizontal = !startFits && endFits ? "end" : "start"
      popover.setAttribute(data("placement"), "\(vertical)-\(horizontal)")

      guard !startFits && !endFits, let placed = popover.getBoundingClientRect() else { return }
      var shift = 0.0
      if placed.right > viewportWidth - margin {
        shift = viewportWidth - margin - placed.right
      }
      if placed.left + shift < margin {
        shift = margin - placed.left
      }
      popover.style.setProperty("translate", "\(Int(shift))px 0")
    }
  }

  public class TimeInputHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: TimeInputHydration?
    private var instances: [TimeInputInstance] = []

    public init() {
      for root in document.querySelectorAll(".time-input-view") {
        hydrate(element: root)
      }
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".time-input-view") != nil else { return }
      instance = TimeInputHydration()
    }

    /// Binds one input; one already bound is left as it is.
    public func hydrate(element: DOM.Element) {
      if let _ = element.getAttribute(data("hydrated")) { return }
      instances.append(TimeInputInstance(root: element))
    }
  }

  public enum TimeInputFactory {
    public static func createElement(
      id: String,
      name: String,
      value: String = "",
      placeholder: String = "Select a time",
      range: Bool = false,
      fullWidth: Bool = true,
      class: String = "",
      hydrator: TimeInputHydration? = nil
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      let view = TimeInputView(
        id: id,
        name: name,
        value: value,
        placeholder: placeholder,
        range: range,
        fullWidth: fullWidth,
        class: `class`
      )
      wrapper.innerHTML = view.render()
      let element = wrapper.firstElementChild ?? wrapper
      hydrator?.hydrate(element: element)
      return element
    }
  }
#endif
