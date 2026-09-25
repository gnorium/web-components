import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

// DatePickerView builds on both sides so DatePickerFactory can draw one on the
// client (the filter bar adds fields there). build() stays embedded-safe:
// stringIsEmpty/stringEquals, `if let` rather than `== nil` on a String?.

/// A field that holds a day, picked from Gnorium's own calendar rather than
/// the browser's: one popover on every device and pointer, styled like the
/// rest of the page, where the native pickers differ by platform and cannot
/// be restyled.
///
/// The field shows the day in words ("Sep 25, 2026"); a hidden input carries
/// it as `yyyy-mm-dd` under `name`, which is what the form submits. The field
/// is read-only and asks for no keyboard: tapping it opens the calendar.
public struct DatePickerView: HTMLContent {
  let id: String
  let name: String
  /// `yyyy-mm-dd`, or empty for no day.
  let value: String
  let placeholder: String
  /// Earliest and latest days that can be picked, `yyyy-mm-dd`.
  let min: String?
  let max: String?
  let weekStart: Weekday
  let labelText: String
  let fullWidth: Bool
  let disabled: Bool
  let `class`: String
  /// The id of the form it submits with, when it sits outside that form.
  let form: String?

  /// The day a week starts on, the calendar's first column.
  public enum Weekday: Int, Sendable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
  }

  public init(
    id: String,
    name: String,
    value: String = "",
    placeholder: String = "Select a date",
    min: String? = nil,
    max: String? = nil,
    weekStart: Weekday = .sunday,
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
    self.min = min
    self.max = max
    self.weekStart = weekStart
    self.labelText = label
    self.fullWidth = fullWidth
    self.disabled = disabled
    self.`class` = `class`
    self.form = form
  }

  public func build() -> DOM.Node {
    let selected = CalendarDate.parse(value)
    let minDate = min.flatMap { CalendarDate.parse($0) }
    let maxDate = max.flatMap { CalendarDate.parse($0) }
    let today = CalendarDate.today()
    let focused = (selected ?? today).clamped(min: minDate, max: maxDate)
    let monthLabelID = "\(id)-month"
    let rootClass = stringIsEmpty(`class`)
      ? "date-picker-view\(fullWidth ? " date-picker-full-width" : "")"
      : "date-picker-view\(fullWidth ? " date-picker-full-width" : "") \(`class`)"

    var valueInput = input()
      .type(.hidden)
      .name(name)
      .value(selected?.iso ?? "")
      .class("date-picker-value")
    if let form {
      valueInput = valueInput.form(form)
    }

    return div {
      valueInput

      TextInputView(
        id: id,
        name: "",
        placeholder: placeholder,
        value: selected?.display ?? "",
        disabled: disabled,
        readonly: true,
        label: labelText,
        fullWidth: fullWidth,
        class: "date-picker-field",
        inputMode: HTML.InputMode.none
      )

      ButtonView(
        icon: IconView { CalendarIconView() },
        weight: .plain,
        size: .medium,
        disabled: disabled,
        ariaLabel: "Choose date",
        class: "date-picker-toggle"
      )

      PopoverView(
        id: "\(id)-popover",
        placement: .bottomStart,
        showsArrow: false,
        ariaLabel: "Choose date",
        class: "date-picker-popover",
        header: {
          ButtonView(
            icon: IconView { PreviousIconView() },
            weight: .quiet,
            size: .medium,
            ariaLabel: "Previous month",
            class: "date-picker-previous"
          )
          h2 { focused.monthTitle }
            .id(monthLabelID)
            .class("date-picker-month-title")
            .ariaLive(.polite)
          ButtonView(
            icon: IconView { NextIconView() },
            weight: .quiet,
            size: .medium,
            ariaLabel: "Next month",
            class: "date-picker-next"
          )
        },
        body: {
          DatePickerMonthView(
            month: focused,
            selected: selected,
            today: today,
            focused: focused,
            min: minDate,
            max: maxDate,
            weekStart: weekStart.rawValue,
            labelID: monthLabelID
          )
        },
        footer: {
          div {
            ButtonView(
              label: "Reset",
              buttonColor: .blue,
              weight: .plain,
              size: .medium,
              class: "date-picker-reset",
              labelFontWeight: fontWeightNormal
            )
            ButtonView(
              label: "Done",
              buttonColor: .blue,
              weight: .plain,
              size: .medium,
              class: "date-picker-done"
            )
          }
          .class("date-picker-footer")
        }
      )
    }
    .class(rootClass)
    .data("week-start", "\(weekStart.rawValue)")
    .data("min", minDate?.iso ?? "")
    .data("max", maxDate?.iso ?? "")
    .data("open", false)
    .style {
      selector("&") {
        position(.relative)
        display(.inlineBlock)
        fontFamily(typographyFontSans)
      }
      selector("&.date-picker-full-width") { width(perc(100)) }

      // The field is a button in an input's clothes: the selects' 40px, no
      // caret, no text selection, the base background rather than the
      // read-only grey, and room at the end for the calendar button.
      descendant(".date-picker-field .text-input-input") {
        height(minSizeInteractiveTouch).important()
        minHeight(minSizeInteractiveTouch).important()
        paddingBlock(0).important()
        paddingInlineEnd(calc("\(spacing8.value) + \(size32.value) + \(spacing4.value)")).important()
        backgroundColor(backgroundColorBase).important()
        cursor(.pointer).important()
        userSelect(.none)
      }
      descendant(".date-picker-field.text-input-disabled .text-input-input") {
        backgroundColor(backgroundColorDisabled).important()
        cursor(cursorNotAllowed).important()
      }
      // Read-only fields drop the text input's focus ring; this one is a
      // control, so it keeps it, and wears it while its calendar is open.
      descendant(".date-picker-field .text-input-input:focus") {
        borderColor(borderColorBlue).important()
        outline(.none).important()
        boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
      }
      selector("&[data-open='true'] .date-picker-field .text-input-input") {
        borderColor(borderColorBlue).important()
        boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
      }

      // The calendar button sits inside the field's border, centred in its
      // 40px, where a text input's end icon sits: a plain button, with no fill
      // and no hover disc to cross the border or the focus ring.
      descendant(".date-picker-toggle") {
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

      // As wide as the field, like a dropdown's menu, the grid's columns
      // sharing the width; never narrower than seven 40px days while the
      // screen allows. Border only, no shadow. Under the field, or over it
      // when the viewport has no room below; the client picks on opening,
      // and anchors a popover wider than its field at whichever edge keeps
      // it on screen.
      descendant(".date-picker-popover") {
        minWidth(calc("min(\(minSizeInteractiveTouch.value) * 7 + \(spacing8.value) * 2 + \(borderWidthBase.value) * 2, 100vw - \(spacing16.value) * 2)")).important()
        maxWidth(.none).important()
        boxShadow(.none).important()
        boxSizing(.borderBox)
      }
      descendant(".date-picker-popover[data-placement^='bottom']") {
        top(calc("100% + \(spacing4.value)"))
      }
      descendant(".date-picker-popover[data-placement^='top']") {
        bottom(calc("100% + \(spacing4.value)"))
      }
      descendant(".date-picker-popover[data-placement$='start']") {
        insetInlineStart(0)
        insetInlineEnd(0)
      }
      descendant(".date-picker-popover[data-placement$='end']") {
        insetInlineStart(.auto)
        insetInlineEnd(0)
      }

      descendant(".date-picker-popover .popover-header") {
        padding(spacing8).important()
      }
      descendant(".date-picker-month-title") {
        flex(1)
        margin(0)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightSemiBold)
        lineHeight(lineHeightSmall22)
        textAlign(.center)
        color(colorBase)
      }
      descendant(".date-picker-popover .popover-body") {
        padding(spacing8).important()
      }
      descendant(".date-picker-popover .popover-footer") {
        padding(spacing4, spacing8).important()
      }
      descendant(".date-picker-footer") {
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

  private final class DatePickerInstance: @unchecked Sendable {
    private let root: DOM.Element
    private let valueInput: HTML.HTMLInputElement?
    private let field: HTML.HTMLInputElement?
    private let toggle: DOM.Element?
    private let popover: DOM.Element?
    private let monthTitle: DOM.Element?
    private let grid: DOM.Element?
    private let previousButton: DOM.Element?
    private let nextButton: DOM.Element?
    private let resetButton: DOM.Element?
    private let doneButton: DOM.Element?
    private let weekStart: Int
    private let minDate: CalendarDate?
    private let maxDate: CalendarDate?
    private let monthLabelID: String
    /// The month on show; its day is not used.
    private var shown: CalendarDate
    /// The day that holds the grid's focus.
    private var focused: CalendarDate
    private var isOpen = false

    init(root: DOM.Element) {
      self.root = root
      valueInput = root.querySelector(".date-picker-value") as? HTML.HTMLInputElement
      field = root.querySelector(".date-picker-field .text-input-input") as? HTML.HTMLInputElement
      toggle = root.querySelector(".date-picker-toggle")
      popover = root.querySelector(".date-picker-popover")
      monthTitle = root.querySelector(".date-picker-month-title")
      grid = root.querySelector(".date-picker-popover .popover-body")
      previousButton = root.querySelector(".date-picker-previous")
      nextButton = root.querySelector(".date-picker-next")
      resetButton = root.querySelector(".date-picker-reset")
      doneButton = root.querySelector(".date-picker-done")
      weekStart = parseInt(root.getAttribute(data("week-start")) ?? "0") ?? 0
      minDate = CalendarDate.parse(root.getAttribute(data("min")) ?? "")
      maxDate = CalendarDate.parse(root.getAttribute(data("max")) ?? "")
      monthLabelID = monthTitle.map { $0.getAttribute("id") ?? "" } ?? ""
      let start = CalendarDate.today()
      shown = start
      focused = start

      root.setAttribute(data("hydrated"), true)
      if let field {
        field.setAttribute("aria-haspopup", "dialog")
        field.setAttribute("aria-expanded", "false")
        if let popover, let popoverID = popover.getAttribute("id") {
          field.setAttribute("aria-controls", popoverID)
        }
      }
      // The field is the keyboard's way in; the button is a target for the
      // pointer, so it takes no Tab stop of its own.
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
            self.setValue(nil)
          }
        }
      }
      if let toggle {
        _ = toggle.addEventListener(.click) { [self] _ in
          if self.isOpen { self.close(returnFocus: true) } else { self.open(fromKeyboard: false) }
        }
      }
      if let previousButton {
        _ = previousButton.addEventListener(.click) { [self] _ in self.page(byMonths: -1) }
      }
      if let nextButton {
        _ = nextButton.addEventListener(.click) { [self] _ in self.page(byMonths: 1) }
      }
      // Reset empties the field and brings the calendar back to today.
      if let resetButton {
        _ = resetButton.addEventListener(.click) { [self] _ in
          self.setValue(nil)
          self.focused = CalendarDate.today().clamped(min: self.minDate, max: self.maxDate)
          self.shown = self.focused
          self.render()
        }
      }
      if let doneButton {
        _ = doneButton.addEventListener(.click) { [self] _ in
          self.close(returnFocus: true)
        }
      }
      if let grid {
        _ = grid.addEventListener(.click) { [self] event in
          guard let target = event.target,
            let cell = target.closest(".date-picker-month-day"),
            let iso = cell.getAttribute(data("date")),
            let date = CalendarDate.parse(iso)
          else { return }
          if let disabled = cell.getAttribute("aria-disabled"), stringEquals(disabled, "true") { return }
          self.select(date, fromKeyboard: false)
        }
        _ = grid.addEventListener(.keydown) { [self] event in
          self.handleGridKey(event)
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
      // A tap or click anywhere else closes it, as every menu on the page.
      // Judged on the press, not the click: picking a day redraws the grid,
      // and by the click the day pressed is no longer in the page.
      _ = document.addEventListener(.mousedown) { [self] event in
        guard self.isOpen, let target = event.target else { return }
        if !self.root.contains(target) {
          self.close(returnFocus: false)
        }
      }
    }

    private func handleGridKey(_ event: Event) {
      let key = event.key
      // Left and right are the line's directions: in a right-to-left page
      // the next day is to the left.
      let forward = isRightToLeft() ? -1 : 1
      var target: CalendarDate?
      if stringEquals(key, "ArrowLeft") {
        target = focused.adding(days: -forward)
      } else if stringEquals(key, "ArrowRight") {
        target = focused.adding(days: forward)
      } else if stringEquals(key, "ArrowUp") {
        target = focused.adding(days: -7)
      } else if stringEquals(key, "ArrowDown") {
        target = focused.adding(days: 7)
      } else if stringEquals(key, "PageUp") {
        target = focused.adding(months: event.shiftKey ? -12 : -1)
      } else if stringEquals(key, "PageDown") {
        target = focused.adding(months: event.shiftKey ? 12 : 1)
      } else if stringEquals(key, "Home") {
        target = focused.adding(days: -((focused.weekday - weekStart + 7) % 7))
      } else if stringEquals(key, "End") {
        target = focused.adding(days: 6 - (focused.weekday - weekStart + 7) % 7)
      } else if stringEquals(key, "Enter") || stringEquals(key, " ") {
        event.preventDefault()
        if focused.isWithin(min: minDate, max: maxDate) {
          select(focused, fromKeyboard: true)
        }
        return
      }
      guard let target else { return }
      event.preventDefault()
      moveFocus(to: target)
    }

    /// Tab stays in the calendar while it is open, coming round at either end.
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

    private func currentValue() -> CalendarDate? {
      CalendarDate.parse(valueInput?.value ?? "")
    }

    private func open(fromKeyboard: Bool) {
      guard let popover else { return }
      if let _ = field?.getAttribute("disabled") { return }
      let start = (currentValue() ?? CalendarDate.today()).clamped(min: minDate, max: maxDate)
      focused = start
      shown = start
      render()
      isOpen = true
      popover.setAttribute(data("open"), true)
      root.setAttribute(data("open"), true)
      field?.setAttribute("aria-expanded", "true")
      position()
      focusDay(visible: fromKeyboard)
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

    /// Picks the day, or unpicks the day already picked. The field shows it
    /// at once and the calendar stays open until Done, Esc or a tap outside.
    private func select(_ date: CalendarDate, fromKeyboard: Bool) {
      if let current = currentValue(), current.isSameDay(as: date) {
        setValue(nil)
      } else {
        setValue(date)
      }
      focused = date
      shown = date
      render()
      focusDay(visible: fromKeyboard)
    }

    private func setValue(_ date: CalendarDate?) {
      valueInput?.value = date?.iso ?? ""
      field?.value = date?.display ?? ""
      valueInput?.dispatchEvent(.input)
      valueInput?.dispatchEvent(.change)
    }

    private func page(byMonths months: Int) {
      focused = focused.adding(months: months).clamped(min: minDate, max: maxDate)
      shown = focused
      render()
    }

    private func moveFocus(to date: CalendarDate) {
      let target = date.clamped(min: minDate, max: maxDate)
      if target.isSameMonth(as: shown) {
        grid?.querySelector("[data-date=\"\(focused.iso)\"]")?.setAttribute("tabindex", "-1")
        focused = target
        grid?.querySelector("[data-date=\"\(focused.iso)\"]")?.setAttribute("tabindex", "0")
      } else {
        focused = target
        shown = target
        render()
      }
      focusDay(visible: true)
    }

    private func focusDay(visible: Bool) {
      grid?.querySelector("[data-date=\"\(focused.iso)\"]")?
        .focus(DOM.FocusOptions(preventScroll: true, focusVisible: visible))
    }

    /// Draws the month on show, and bars paging past the bounds.
    private func render() {
      monthTitle?.textContent = shown.monthTitle
      let view = DatePickerMonthView(
        month: shown,
        selected: currentValue(),
        today: CalendarDate.today(),
        focused: focused,
        min: minDate,
        max: maxDate,
        weekStart: weekStart,
        labelID: monthLabelID
      )
      grid?.innerHTML = view.render()
      let shownIndex = shown.year * 12 + shown.month
      setDisabled(previousButton, minDate.map { $0.year * 12 + $0.month >= shownIndex } ?? false)
      setDisabled(nextButton, maxDate.map { $0.year * 12 + $0.month <= shownIndex } ?? false)
    }

    private func setDisabled(_ button: DOM.Element?, _ disabled: Bool) {
      guard let button else { return }
      if disabled {
        button.setAttribute("disabled", "true")
      } else {
        button.removeAttribute("disabled")
      }
    }

    // MARK: - Placement

    private func isRightToLeft() -> Bool {
      guard let holder = root.closest("[dir]"), let dir = holder.getAttribute("dir") else { return false }
      return stringEquals(dir, "rtl")
    }

    /// Under the field unless the viewport has no room there and more above;
    /// from the start edge unless that runs off screen and the end does not;
    /// nudged back on screen when neither fits (a narrow phone).
    private func position() {
      guard let popover else { return }
      popover.setAttribute(data("placement"), "bottom-start")
      popover.style.setProperty("translate", "")
      guard let anchor = root.getBoundingClientRect(),
        let fieldRect = field?.getBoundingClientRect(),
        let rect = popover.getBoundingClientRect()
      else { return }
      let margin = 8.0
      let viewportWidth = window.innerWidth
      let viewportHeight = window.innerHeight
      let roomBelow = viewportHeight - fieldRect.bottom
      let roomAbove = anchor.top
      let vertical = roomBelow < rect.height + margin && roomAbove > roomBelow ? "top" : "bottom"

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

  public class DatePickerHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: DatePickerHydration?
    private var instances: [DatePickerInstance] = []

    public init() {
      for root in document.querySelectorAll(".date-picker-view") {
        hydrate(element: root)
      }
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".date-picker-view") != nil else { return }
      instance = DatePickerHydration()
    }

    /// Binds one picker; one already bound is left as it is.
    public func hydrate(element: DOM.Element) {
      if let _ = element.getAttribute(data("hydrated")) { return }
      instances.append(DatePickerInstance(root: element))
    }
  }

  public enum DatePickerFactory {
    public static func createElement(
      id: String,
      name: String,
      value: String = "",
      placeholder: String = "Select a date",
      min: String? = nil,
      max: String? = nil,
      weekStart: DatePickerView.Weekday = .sunday,
      fullWidth: Bool = true,
      class: String = "",
      hydrator: DatePickerHydration? = nil
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      let view = DatePickerView(
        id: id,
        name: name,
        value: value,
        placeholder: placeholder,
        min: min,
        max: max,
        weekStart: weekStart,
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
