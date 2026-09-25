import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// One month as a grid of days, six weeks of seven: the days of the months
/// either side muted, today ringed, the chosen day filled (activating it again
/// unpicks it). The ARIA grid a
/// date picker moves through with the keyboard — one day, the focused one,
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

  public init(
    month: CalendarDate,
    selected: CalendarDate? = nil,
    today: CalendarDate,
    focused: CalendarDate,
    min: CalendarDate? = nil,
    max: CalendarDate? = nil,
    weekStart: Int = 0,
    labelID: String
  ) {
    self.month = month
    self.selected = selected
    self.today = today
    self.focused = focused
    self.min = min
    self.max = max
    self.weekStart = weekStart
    self.labelID = labelID
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
              let isSelected = selected.map { $0.isSameDay(as: date) } ?? false
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
              .ariaSelected(isSelected)
              // The chosen day clears when activated again; its name says so.
              .ariaLabel(isSelected ? "\(date.spoken), selected. Activate to clear." : date.spoken)
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
        fontFamily(typographyFontSans)
        fontSize(fontSizeSmall14)
        color(colorBase)
      }
      descendant(".date-picker-month-weekday") {
        blockSize(minSizeInteractivePointer)
        padding(0)
        fontWeight(fontWeightSemiBold)
        fontSize(fontSizeXSmall12)
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
        lineHeight(1)
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
