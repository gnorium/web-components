import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A date picker's shortcut grid: the twelve months of a year, or a page of
/// years—a decade, with the years either side of it muted, as the day grid
/// mutes the days of the months either side—three to a row. Reached from the
/// calendar's caption; picking a month goes back to that month's days,
/// picking a year to that year's months. The same look as the day grid
/// (DatePickerMonthView): its cell height, type and states—the current
/// month or year ringed, the chosen one filled, out-of-bounds ones disabled—
/// and the same roving tabindex.
///
/// Built on both sides: the server renders it hidden, the client draws it
/// when the reader opens it.
public struct DatePickerPeriodView: HTMLContent {
  /// What the grid holds.
  public enum Kind: Sendable {
    /// The twelve months of the shown day's year.
    case months
    /// The decade the shown day's year falls in, and the year either side.
    case years
  }

  let kind: Kind
  /// The year on show (months) or a year of the decade on show (years).
  let shown: CalendarDate
  /// The days chosen: the picked day, or a range's ends.
  let selected: [CalendarDate]
  let today: CalendarDate
  /// The month or year that takes Tab and the keyboard's focus.
  let focused: CalendarDate
  let min: CalendarDate?
  let max: CalendarDate?
  /// The id of the element naming the year or decade, for the grid's label.
  let labelID: String

  public init(
    kind: Kind,
    shown: CalendarDate,
    selected: [CalendarDate] = [],
    today: CalendarDate,
    focused: CalendarDate,
    min: CalendarDate? = nil,
    max: CalendarDate? = nil,
    labelID: String
  ) {
    self.kind = kind
    self.shown = shown
    self.selected = selected
    self.today = today
    self.focused = focused
    self.min = min
    self.max = max
    self.labelID = labelID
  }

  /// The first year of the decade a year falls in: 2020 for 2026.
  public static func decadeStart(_ year: Int) -> Int {
    year - ((year % 10) + 10) % 10
  }

  /// A month as one number, for comparing months across years.
  public static func monthIndex(_ date: CalendarDate) -> Int {
    date.year * 12 + date.month - 1
  }

  /// Whether a month holds a day within the bounds.
  public static func isMonthWithin(year: Int, month: Int, min: CalendarDate?, max: CalendarDate?) -> Bool {
    let index = year * 12 + month - 1
    if let min, index < monthIndex(min) { return false }
    if let max, index > monthIndex(max) { return false }
    return true
  }

  /// Whether a year holds a day within the bounds.
  public static func isYearWithin(_ year: Int, min: CalendarDate?, max: CalendarDate?) -> Bool {
    if let min, year < min.year { return false }
    if let max, year > max.year { return false }
    return true
  }

  /// The caption over the grid: "2026", or the decade, "2020–2029".
  public static func title(kind: Kind, shown: CalendarDate) -> String {
    switch kind {
    case .months:
      return "\(shown.year)"
    case .years:
      let start = decadeStart(shown.year)
      return "\(start)–\(start + 9)"
    }
  }

  /// One cell: the number it carries (month 1–12, or the year), its text,
  /// its spoken name, and its states.
  private func cell(_ index: Int) -> (
    value: Int, text: String, words: String, isSelected: Bool, isCurrent: Bool, isOutside: Bool,
    isEnabled: Bool, isFocused: Bool
  ) {
    switch kind {
    case .months:
      let month = index + 1
      let year = shown.year
      return (
        month,
        CalendarDate.monthAbbreviations[index],
        "\(CalendarDate.monthNames[index]) \(year)",
        selected.contains { $0.year == year && $0.month == month },
        today.year == year && today.month == month,
        false,
        Self.isMonthWithin(year: year, month: month, min: min, max: max),
        focused.year == year && focused.month == month
      )
    case .years:
      let year = Self.decadeStart(shown.year) - 1 + index
      return (
        year,
        "\(year)",
        "\(year)",
        selected.contains { $0.year == year },
        today.year == year,
        index == 0 || index == 11,
        Self.isYearWithin(year, min: min, max: max),
        focused.year == year
      )
    }
  }

  public func build() -> DOM.Node {
    table {
      tbody {
        for row in 0..<4 {
          tr {
            for column in 0..<3 {
              let state = cell(row * 3 + column)
              let base = td {
                span { state.text }
                  .class("date-picker-period-label")
              }
              .class("date-picker-period-cell")
              .role(.gridcell)
              .tabindex(state.isFocused ? 0 : -1)
              .data("value", "\(state.value)")
              .data("outside", state.isOutside)
              .data("current", state.isCurrent)
              .ariaSelected(state.isSelected)
              .ariaLabel(state.words)
              let current = state.isCurrent ? base.ariaCurrent("date") : base
              state.isEnabled ? current : current.ariaDisabled(true)
            }
          }
        }
      }
    }
    .class("date-picker-period-view")
    .data("kind", kind == .months ? "months" : "years")
    .role(.grid)
    .ariaLabelledby(labelID)
    .style {
      selector("&") {
        borderCollapse(.collapse)
        borderSpacing(0)
        tableLayout(.fixed)
        width(perc(100))
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        color(colorBase)
      }
      // The day grid's cell: the cell the target, the pill inside it what
      // shows. Its four rows take the day grid's whole height—its weekday
      // row and six weeks—so the popover keeps one height on every grid
      // (user, 2026-10-12); each is taller than the 40px a finger needs.
      descendant(".date-picker-period-cell") {
        blockSize(calc("(\(minSizeInteractivePointer.value) + \(minSizeInteractiveTouch.value) * 6) / 4"))
        padding(0)
        textAlign(.center)
        verticalAlign(.middle)
        cursor(.pointer)
        outline(.none)
      }
      // The day's circle drawn as a pill wide enough for a year.
      descendant(".date-picker-period-label") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        inlineSize(size64)
        blockSize(size32)
        boxSizing(.borderBox)
        border(borderWidthBase, .solid, borderColorTransparent)
        borderRadius(borderRadiusPill)
        fontVariantNumeric(.tabularNums)
        lineHeight(lineHeightSmall22)
        transition("background-color 0.1s ease, color 0.1s ease")
      }
      descendant(".date-picker-period-cell[data-outside='true'] .date-picker-period-label") {
        color(colorSubtle)
      }
      descendant(".date-picker-period-cell[data-current='true'] .date-picker-period-label") {
        color(colorBlue)
        fontWeight(fontWeightSemiBold)
        borderColor(borderColorBlue)
      }
      descendant(".date-picker-period-cell:hover:not([aria-disabled='true']) .date-picker-period-label") {
        backgroundColor(backgroundColorInteractiveSubtleHover)
      }
      descendant(".date-picker-period-cell[aria-selected='true'] .date-picker-period-label") {
        backgroundColor(backgroundColorBlue).important()
        color(colorInvertedFixed).important()
        fontWeight(fontWeightSemiBold)
        borderColor(borderColorTransparent)
      }
      descendant(".date-picker-period-cell[aria-disabled='true']") {
        cursor(cursorNotAllowed)
      }
      descendant(".date-picker-period-cell[aria-disabled='true'] .date-picker-period-label") {
        color(colorDisabled).important()
      }
      descendant(".date-picker-period-cell:focus-visible .date-picker-period-label") {
        outline(borderWidthThick, .solid, borderColorBlueFocus)
        outlineOffset(borderWidthBase)
      }
    }
  }
}
