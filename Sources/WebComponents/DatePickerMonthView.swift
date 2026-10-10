import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// One month as a grid of days, six weeks of seven: the days of the months
/// either side muted, today ringed, the chosen day filled (activating it again
/// unpicks it)—or, for a range, its two ends filled and the days between
/// tinted. The ARIA grid a
/// date picker moves through with the keyboard—one day, the focused one,
/// takes Tab (roving tabindex).
///
/// Built on both sides: the server renders the first month, the client
/// redraws it as the reader pages through months.
public struct DatePickerMonthView: HTMLContent {
  /// The month shown; its day is ignored.
  let month: CalendarDate
  let selected: CalendarDate?
  let today: CalendarDate
  /// The day that takes Tab and the keyboard's focus.
  let focused: CalendarDate
  let min: CalendarDate?
  let max: CalendarDate?
  /// 0 for Sunday.
  let weekStart: Int
  /// The id of the element naming the month, for the grid's label.
  let labelID: String
  /// A range's first and last day, when the grid picks a range; either may
  /// be open.
  let rangeStart: CalendarDate?
  let rangeEnd: CalendarDate?
  let isRange: Bool

  public init(
    month: CalendarDate,
    selected: CalendarDate? = nil,
    today: CalendarDate,
    focused: CalendarDate,
    min: CalendarDate? = nil,
    max: CalendarDate? = nil,
    weekStart: Int = 0,
    labelID: String,
    isRange: Bool = false,
    rangeStart: CalendarDate? = nil,
    rangeEnd: CalendarDate? = nil
  ) {
    self.month = month
    self.selected = selected
    self.today = today
    self.focused = focused
    self.min = min
    self.max = max
    self.weekStart = weekStart
    self.labelID = labelID
    self.isRange = isRange
    self.rangeStart = rangeStart
    self.rangeEnd = rangeEnd
  }

  /// How the grid marks a day of a range: an end, a day between, or neither.
  private func rangeRole(_ date: CalendarDate) -> (isEnd: Bool, isBetween: Bool, words: String) {
    let isStart = rangeStart.map { $0.isSameDay(as: date) } ?? false
    let isLast = rangeEnd.map { $0.isSameDay(as: date) } ?? false
    if isStart && isLast { return (true, false, "\(date.spoken), the range's only day") }
    if isStart { return (true, false, "\(date.spoken), start of range") }
    if isLast { return (true, false, "\(date.spoken), end of range") }
    guard let first = rangeStart, let last = rangeEnd,
      date.dayNumber > first.dayNumber, date.dayNumber < last.dayNumber
    else { return (false, false, date.spoken) }
    return (false, true, "\(date.spoken), in range")
  }

  public func build() -> DOM.Node {
    let first = CalendarDate(year: month.year, month: month.month, day: 1)
    let lead = (first.weekday - weekStart + 7) % 7
    let gridStart = first.dayNumber - lead
    let columns = [0, 1, 2, 3, 4, 5, 6].map { ($0 + weekStart) % 7 }

    return table {
      thead {
        tr {
          for weekday in columns {
            th { CalendarDate.weekdayAbbreviations[weekday] }
              .scope(.col)
              .abbr(CalendarDate.weekdayNames[weekday])
              .class("date-picker-month-weekday")
          }
        }
      }
      tbody {
        for week in 0..<6 {
          tr {
            for column in 0..<7 {
              let date = CalendarDate(dayNumber: gridStart + week * 7 + column)
              let role = rangeRole(date)
              let isSelected = isRange ? role.isEnd : selected.map { $0.isSameDay(as: date) } ?? false
              let isToday = today.isSameDay(as: date)
              let isOutside = !date.isSameMonth(as: month)
              let isEnabled = date.isWithin(min: min, max: max)
              let isFocused = focused.isSameDay(as: date)
              let cell = td {
                span { "\(date.day)" }
                  .class("date-picker-month-day-label")
              }
              .class("date-picker-month-day")
              .role(.gridcell)
              .tabindex(isFocused ? 0 : -1)
              .data("date", date.iso)
              .data("outside", isOutside)
              .data("today", isToday)
              .data("in-range", role.isBetween)
              .ariaSelected(isSelected)
              // The chosen day clears when activated again; its name says so.
              // A range's days say where in the range they stand.
              .ariaLabel(
                isRange ? role.words : isSelected ? "\(date.spoken), selected. Activate to clear." : date.spoken)
              let current = isToday ? cell.ariaCurrent("date") : cell
              isEnabled ? current : current.ariaDisabled(true)
            }
          }
        }
      }
    }
    .class("date-picker-month-view")
    .role(.grid)
    .ariaLabelledby(labelID)
    .style {
      selector("&") {
        borderCollapse(.collapse)
        borderSpacing(0)
        tableLayout(.fixed)
        width(perc(100))
        // The seven columns shrink to the popover's width, never under 32
        // a day (user, 2026-10-10).
        minWidth(calc("\(size32.value) * 7"))
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        color(colorBase)
      }
      descendant(".date-picker-month-weekday") {
        blockSize(minSizeInteractivePointer)
        padding(0)
        fontWeight(fontWeightSemiBold)
        fontSize(fontSizeMedium16)
        color(colorSubtle)
        textAlign(.center)
      }
      // The cell is the target; the circle inside it is what shows. Columns
      // give up width before the grid overflows a narrow phone, and a row
      // keeps the 40px a finger needs.
      descendant(".date-picker-month-day") {
        blockSize(minSizeInteractiveTouch)
        padding(0)
        textAlign(.center)
        verticalAlign(.middle)
        cursor(.pointer)
        outline(.none)
      }
      descendant(".date-picker-month-day-label") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        inlineSize(size32)
        blockSize(size32)
        boxSizing(.borderBox)
        border(borderWidthBase, .solid, borderColorTransparent)
        borderRadius(borderRadiusCircle)
        fontVariantNumeric(.tabularNums)
        lineHeight(lineHeightSmall22)
        transition("background-color 0.1s ease, color 0.1s ease")
      }
      descendant(".date-picker-month-day[data-outside='true'] .date-picker-month-day-label") {
        color(colorSubtle)
      }
      descendant(".date-picker-month-day[data-today='true'] .date-picker-month-day-label") {
        color(colorBlue)
        fontWeight(fontWeightSemiBold)
        borderColor(borderColorBlue)
      }
      descendant(".date-picker-month-day:hover:not([aria-disabled='true']) .date-picker-month-day-label") {
        backgroundColor(backgroundColorInteractiveSubtleHover)
      }
      // The days between a range's ends, tinted as a selected row is.
      descendant(".date-picker-month-day[data-in-range='true'] .date-picker-month-day-label") {
        backgroundColor(backgroundColorBlueSubtle)
        color(colorBlue)
      }
      descendant(".date-picker-month-day[aria-selected='true'] .date-picker-month-day-label") {
        backgroundColor(backgroundColorBlue).important()
        color(colorInvertedFixed).important()
        fontWeight(fontWeightSemiBold)
        borderColor(borderColorTransparent)
      }
      descendant(".date-picker-month-day[aria-disabled='true']") {
        cursor(cursorNotAllowed)
      }
      descendant(".date-picker-month-day[aria-disabled='true'] .date-picker-month-day-label") {
        color(colorDisabled).important()
      }
      // The ring every control wears for keyboard focus, round the circle.
      descendant(".date-picker-month-day:focus-visible .date-picker-month-day-label") {
        outline(borderWidthThick, .solid, borderColorBlueFocus)
        outlineOffset(borderWidthBase)
      }
    }
  }
}
