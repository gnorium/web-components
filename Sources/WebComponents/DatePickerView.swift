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
///
/// A range picker (`range: true`) holds a range of the reader's days instead
/// (`DateRangeValue`): presets on the left—Today, Last 7, 30 and 90 days—
/// and the calendar on the right, as Google Analytics, Stripe, Grafana and
/// Datadog lay theirs out. A preset selects its days in the calendar and
/// stays relative in the value (`-7d..`); two days picked in the calendar
/// make a fixed range—the UTC instants that bound those local days
/// (`2026-09-30T18:30Z..2026-10-08T18:30Z`, Oct 1–8 in India)—the first alone
/// an open one. The field shows it in words ("Oct 1 – Oct 8, 2026",
/// "Last 7 days"). On a phone the presets sit above the calendar.
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
  /// Whether it holds a range of days rather than one.
  let range: Bool
  /// A range picker's presets, each a relative `DateRangeValue`.
  let presets: [(value: String, label: String)]

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
    form: String? = nil,
    range: Bool = false,
    presets: [(value: String, label: String)] = DateRangeValue.presets
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
    self.range = range
    self.presets = range ? presets : []
  }

  public func build() -> DOM.Node {
    let selected = range ? nil : CalendarDate.parse(value)
    let rangeValue = range ? DateRangeValue.parse(value) : nil
    let minDate = min.flatMap { CalendarDate.parse($0) }
    let maxDate = max.flatMap { CalendarDate.parse($0) }
    let now = ViewerZone.nowMinutes()
    // The reader's days, both kinds (ViewerZone): a range's instants are
    // drawn as the days they bound.
    let today = ViewerZone.localDay(epochMinutes: now)
    let rangeDays = rangeValue.map { $0.days(now: now) }
    let rangeStart = rangeDays.flatMap { $0.start }
    let rangeEnd = rangeDays.flatMap { $0.end }
    let focused = (selected ?? rangeEnd ?? rangeStart ?? today).clamped(min: minDate, max: maxDate)
    let monthLabelID = "\(id)-month"
    let rootClass = stringIsEmpty(`class`)
      ? "date-picker-view\(fullWidth ? " date-picker-full-width" : "")"
      : "date-picker-view\(fullWidth ? " date-picker-full-width" : "") \(`class`)"
    let rangeParam = rangeValue.map { $0.param } ?? ""
    let month = DatePickerMonthView(
      month: focused,
      selected: selected,
      today: today,
      focused: focused,
      min: minDate,
      max: maxDate,
      weekStart: weekStart.rawValue,
      labelID: monthLabelID,
      isRange: range,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd
    )

    var valueInput = input()
      .type(.hidden)
      .name(name)
      .value(range ? rangeParam : selected?.iso ?? "")
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
        value: range ? rangeValue.map { $0.label } ?? "" : selected?.display ?? "",
        disabled: disabled,
        readonly: true,
        label: labelText,
        fullWidth: fullWidth,
        class: "date-picker-field",
        inputMode: HTML.InputMode.none
      )

      ButtonView(
        icon: IconView(icon: { s in CalendarIconView(size: s) }, size: sizeIconSmall),
        weight: .plain,
        size: .medium,
        disabled: disabled,
        ariaLabel: range ? "Choose dates" : "Choose date",
        class: "date-picker-toggle"
      )

      // One day: the month's paging is the popover's header. A range: the
      // presets beside the calendar, the paging over the calendar alone.
      PopoverView(
        id: "\(id)-popover",
        placement: .bottomStart,
        showsArrow: false,
        ariaLabel: range ? "Choose dates" : "Choose date",
        class: "date-picker-popover",
        header: {
          if !range {
            navigation(title: focused.monthTitle, labelID: monthLabelID)
          }
        },
        body: {
          if range {
            div {
              div {
                for preset in presets {
                  ButtonView(
                    label: preset.label,
                    buttonColor: .gray,
                    weight: .plain,
                    size: .medium,
                    disabled: disabled || !(DateRangeValue.parse(preset.value).map {
                      $0.isWithin(min: minDate, max: maxDate, now: now)
                    } ?? false),
                    fullWidth: true,
                    class: "date-picker-preset",
                    labelFontWeight: fontWeightNormal,
                    contentJustifyContent: .flexStart,
                    borderRadius: borderRadiusBase,
                    data: [("value", preset.value)]
                  )
                  .ariaPressed(stringEquals(preset.value, rangeParam))
                }
              }
              .class("date-picker-presets")
              .role(.group)
              .ariaLabel("Presets")

              div {
                // The range's two ends, named as a year range's are (Year
                // start, Year end in FormDateView): read here, picked below.
                div {
                  TextInputView(
                    id: "\(id)-start", name: "", placeholder: "Date start", value: rangeStart?.display ?? "",
                    readonly: true, label: "Date start", tooltip: "Start date of the range.",
                    class: "date-picker-start", inputMode: HTML.InputMode.none)
                  TextInputView(
                    id: "\(id)-end", name: "", placeholder: "Date end", value: rangeEnd?.display ?? "",
                    readonly: true, label: "Date end", tooltip: "End date of the range.",
                    class: "date-picker-end", inputMode: HTML.InputMode.none)
                }
                .class("date-picker-ends")
                div {
                  navigation(title: focused.monthTitle, labelID: monthLabelID)
                }
                .class("date-picker-navigation")
                div { month }
                  .class("date-picker-grid")
              }
              .class("date-picker-calendar")
            }
            .class("date-picker-range")
          } else {
            div { month }
              .class("date-picker-grid")
          }
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
    .data("disabled", disabled)
    .data("range", range)
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

      // The field is a button in an input's clothes: a text input's inset and
      // height, no caret, no text selection, the base background rather than
      // the read-only grey, and room at the end for the calendar button, as
      // a text input's end icon has.
      descendant(".date-picker-field .text-input-input") {
        paddingInlineEnd(calc(spacing8 + sizeIconMedium + spacing8)).important()
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
        outline(borderWidthBase, .solid, borderColorBlueFocus).important()
        outlineOffset(px(0)).important()
      }
      selector("&[data-open='true'] .date-picker-field .text-input-input") {
        borderColor(borderColorBlue).important()
        outline(borderWidthBase, .solid, borderColorBlueFocus).important()
        outlineOffset(px(0)).important()
      }

      // The calendar button sits inside the field's border, centered in its
      // height, where a text input's end icon sits: a plain button, with no fill
      // and no hover disc to cross the border or the focus ring.
      descendant(".date-picker-toggle") {
        position(.absolute)
        // Centered in the field's 40: (40 − 32) / 2.
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

      // Exactly the field's width, as a dropdown's menu is (user,
      // 2026-10-10): the grid's seven columns share it, never under 32 a
      // day. Border only, no shadow. Under the field, or over it when the
      // viewport has no room below. A container, so its contents lay out
      // by its own width.
      descendant(".date-picker-popover") {
        insetInlineStart(0).important()
        insetInlineEnd(0).important()
        width(perc(100)).important()
        minWidth(0).important()
        maxWidth(.none).important()
        boxShadow(.none).important()
        boxSizing(.borderBox)
        containerType(.inlineSize)
      }
      descendant(".date-picker-popover[data-placement^='bottom']") {
        top(calc("100% + \(spacing4.value)"))
      }
      descendant(".date-picker-popover[data-placement^='top']") {
        bottom(calc("100% + \(spacing4.value)"))
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
        padding(spacing8).important()
      }
      descendant(".date-picker-footer") {
        display(.flex)
        flex(1)
        justifyContent(.spaceBetween)
        alignItems(.center)
        gap(spacing8)
      }

      // A range: the presets' column, then the calendar, while the field is
      // wide enough for both.
      descendant(".date-picker-range") {
        display(.grid)
        gridTemplateColumns("max-content minmax(0, 1fr)")
        gap(spacing8)
      }
      descendant(".date-picker-presets") {
        display(.flex)
        flexDirection(.column)
        gap(spacing4)
        paddingInlineEnd(spacing8)
        borderInlineEnd(borderWidthBase, .solid, borderColorBase)
      }
      descendant(".date-picker-preset[aria-pressed='true']") {
        backgroundColor(backgroundColorBlueSubtle).important()
        color(colorBlue).important()
      }
      // The preset in force keeps its blue under the pointer too: the
      // button's hover recolors its label, so the label is held here.
      descendant(".date-picker-preset[aria-pressed='true'] *") {
        color(colorBlue).important()
      }
      descendant(".date-picker-calendar") {
        display(.flex)
        flexDirection(.column)
        gap(spacing8)
        minWidth(0)
      }
      // Date start over Date end, one field a row as every form has it
      // (user, 2026-10-10): side by side, a start could read as the right
      // end of the span.
      descendant(".date-picker-ends") {
        display(.flex)
        flexDirection(.column)
        gap(spacing8)
      }
      descendant(".date-picker-navigation") {
        display(.flex)
        alignItems(.center)
        justifyContent(.spaceBetween)
        gap(spacing8)
      }
      // A popover narrower than the presets and the calendar side by side
      // sets the presets above the calendar, one to a row (user,
      // 2026-10-10): a sidebar's field as a phone's.
      container(maxWidth(maxWidthBreakpointPhoneNarrow)) {
        descendant(".date-picker-range") {
          gridTemplateColumns("minmax(0, 1fr)").important()
        }
        descendant(".date-picker-presets") {
          paddingInlineEnd(0).important()
          paddingBlockEnd(spacing8).important()
          borderInlineEnd(.none).important()
          borderBlockEnd(borderWidthBase, .solid, borderColorBase).important()
        }
      }
    }
  }

  /// The month's paging: previous, the month's name, next.
  @HTMLBuilder
  private func navigation(title: String, labelID: String) -> [DOM.Node] {
    ButtonView(
      icon: IconView(icon: { s in PreviousIconView(size: s) }, size: sizeIconSmall),
      weight: .quiet,
      size: .medium,
      ariaLabel: "Previous month",
      class: "date-picker-previous"
    )
    h2 { title }
      .id(labelID)
      .class("date-picker-month-title")
      .ariaLive(.polite)
    ButtonView(
      icon: IconView(icon: { s in NextIconView(size: s) }, size: sizeIconSmall),
      weight: .quiet,
      size: .medium,
      ariaLabel: "Next month",
      class: "date-picker-next"
    )
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
    /// A range picker's presets.
    private let presets: [DOM.Element]
    /// Whether it holds a range of days (`DateRangeValue`) rather than one.
    private let isRange: Bool
    private let disabled: Bool
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
      grid = root.querySelector(".date-picker-grid")
      previousButton = root.querySelector(".date-picker-previous")
      nextButton = root.querySelector(".date-picker-next")
      resetButton = root.querySelector(".date-picker-reset")
      doneButton = root.querySelector(".date-picker-done")
      presets = root.querySelectorAll(".date-picker-preset")
      isRange = stringEquals(root.getAttribute(data("range")) ?? "", "true")
      disabled = stringEquals(root.getAttribute(data("disabled")) ?? "", "true")
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

      // The server drew the range in the zone the request named; the
      // browser's is the reader's own, so the words are said again in it.
      if isRange, let range = currentRange() {
        field?.value = range.label
      }

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
            self.setRange(nil)
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
          self.setRange(nil)
          self.focused = self.today().clamped(min: self.minDate, max: self.maxDate)
          self.shown = self.focused
          self.render()
        }
      }
      if let doneButton {
        _ = doneButton.addEventListener(.click) { [self] _ in
          self.close(returnFocus: true)
        }
      }
      // A preset selects its days, and stays relative in the value.
      for preset in presets {
        _ = preset.addEventListener(.click) { [self] _ in
          guard let param = preset.getAttribute(data("value")), let range = DateRangeValue.parse(param) else {
            return
          }
          let now = ViewerZone.nowMinutes()
          guard !self.disabled, range.isWithin(min: self.minDate, max: self.maxDate, now: now) else { return }
          self.setRange(range)
          let days = range.days(now: now)
          if let day = days.end ?? days.start {
            self.focused = day.clamped(min: self.minDate, max: self.maxDate)
            self.shown = self.focused
          }
          self.render()
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
      isRange ? nil : CalendarDate.parse(valueInput?.value ?? "")
    }

    private func currentRange() -> DateRangeValue? {
      isRange ? DateRangeValue.parse(valueInput?.value ?? "") : nil
    }

    /// Today, the reader's.
    private func today() -> CalendarDate {
      CalendarDate.today()
    }

    private func open(fromKeyboard: Bool) {
      guard let popover else { return }
      if let _ = field?.getAttribute("disabled") { return }
      let days = currentRange().map { $0.days() }
      let start = (currentValue() ?? days?.end ?? days?.start ?? today()).clamped(min: minDate, max: maxDate)
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
      if isRange {
        // The first day starts a range, open at its end; the second closes
        // it, whichever comes first. A third starts again.
        if let current = currentRange(), !current.isRelative, case .instant? = current.start,
          case .none = current.end, let first = current.days().start
        {
          setRange(DateRangeValue.fixed(first, date))
        } else {
          setRange(DateRangeValue.fixed(date, nil))
        }
      } else if let current = currentValue(), current.isSameDay(as: date) {
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
      guard !isRange else { return }
      valueInput?.value = date?.iso ?? ""
      field?.value = date?.display ?? ""
      valueInput?.dispatchEvent(.input)
      valueInput?.dispatchEvent(.change)
    }

    private func setRange(_ range: DateRangeValue?) {
      guard isRange else { return }
      // Filtering by date: the server counts a relative range's days in
      // the reader's zone from here on.
      if let _ = range { ViewerZoneHydration.remember() }
      valueInput?.value = range.map { $0.param } ?? ""
      field?.value = range.map { $0.label } ?? ""
      valueInput?.dispatchEvent(.input)
      valueInput?.dispatchEvent(.change)
    }

    /// The preset in force pressed, the others not.
    private func markPresets() {
      let param = valueInput?.value ?? ""
      let now = ViewerZone.nowMinutes()
      for preset in presets {
        let value = preset.getAttribute(data("value")) ?? ""
        let pressed = stringEquals(value, param)
        preset.setAttribute("aria-pressed", pressed ? "true" : "false")
        let allowed = !disabled && (DateRangeValue.parse(value).map {
          $0.isWithin(min: minDate, max: maxDate, now: now)
        } ?? false)
        if allowed { preset.removeAttribute("disabled") } else { preset.setAttribute("disabled", "") }
      }
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
      let days = currentRange().map { $0.days() }
      let view = DatePickerMonthView(
        month: shown,
        selected: currentValue(),
        today: today(),
        focused: focused,
        min: minDate,
        max: maxDate,
        weekStart: weekStart,
        labelID: monthLabelID,
        isRange: isRange,
        rangeStart: days?.start,
        rangeEnd: days?.end
      )
      markPresets()
      (root.querySelector(".date-picker-start .text-input-input") as? HTML.HTMLInputElement)?.value =
        days?.start?.display ?? ""
      (root.querySelector(".date-picker-end .text-input-input") as? HTML.HTMLInputElement)?.value =
        days?.end?.display ?? ""
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

    /// Always under the field, as a dropdown opens, and exactly its width
    /// (user, 2026-10-10): the page scrolls on to whatever does not fit.
    private func position() {
      guard let popover else { return }
      popover.setAttribute(data("placement"), "bottom-start")
      popover.style.setProperty("translate", "")
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
      range: Bool = false,
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
        class: `class`,
        range: range
      )
      wrapper.innerHTML = view.render()
      let element = wrapper.firstElementChild ?? wrapper
      hydrator?.hydrate(element: element)
      return element
    }
  }
#endif
