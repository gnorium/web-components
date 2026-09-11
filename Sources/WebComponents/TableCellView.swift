import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// Represents the content and styling for a single table cell.
public struct TableCellView: HTMLContent {
  public enum CellType: Sendable {
    case text(String)
    case mono(String)
    case selection(id: String, name: String, value: String, checked: Bool)
    case status(icon: String, bgColor: CSS.Color)
    case custom([DOM.Node])
  }

  public let columnID: String?
  let type: CellType
  let `class`: String
  let align: TableView.Column.Alignment
  let vAlign: CSS.VerticalAlign
  let useMonoFont: Bool
  let showVerticalBorders: Bool

  public init(
    columnID: String? = nil,
    _ type: CellType,
    class: String = "",
    align: TableView.Column.Alignment = .start,
    verticalAlign: CSS.VerticalAlign = .middle,
    useMonoFont: Bool = false,
    showVerticalBorders: Bool = false
  ) {
    self.columnID = columnID
    self.type = type
    self.`class` = `class`
    self.align = align
    self.vAlign = verticalAlign
    self.useMonoFont = useMonoFont
    self.showVerticalBorders = showVerticalBorders
  }

  public func build() -> DOM.Node {
    let alignValue: String = switch align {
    case .start: "start"
    case .center: "center"
    case .end: "end"
    case .number: "number"
    }

    td {
      switch type {
      case .text(let text):
        DOM.Text(text)
      case .mono(let text):
        span { text }.class("table-cell-mono")
      case .selection(let id, let name, let value, let checked):
        div {
          input()
            .type(.radio)
            .id(id)
            .name(name)
            .value(value)
            .checked(checked)
            .class("table-cell-selection-input")
        }
        .class("table-selection-container")
      case .status(let icon, _):
        span { icon }.class("table-cell-status-icon")
      case .custom(let nodes):
        div {
          for node in nodes { node }
        }
      }
    }
    .class(stringIsEmpty(`class`) ? "table-cell-view" : "table-cell-view \(`class`)")
    .data("align", alignValue)
    .data("vertical-align", vAlign.rawValue)
    .data("mono", useMonoFont)
    .data("vertical-borders", showVerticalBorders)
    .style {
      selector("&") {
        padding(spacing8, spacing12)
        fontFamily(typographyFontSans)
        fontSize(fontSizeSmall14)
        color(colorBase)
        overflow(.hidden)
        textOverflow(.ellipsis)
        whiteSpace(.nowrap)
      }
      selector("&[data-align='start']") { textAlign(.left) }
      selector("&[data-align='center']") { textAlign(.center) }
      selector("&[data-align='end']", "&[data-align='number']") { textAlign(.right) }
      selector("&[data-align='number']") { fontVariantNumeric(.tabularNums) }
      selector("&[data-vertical-align='top']") { verticalAlign(.top) }
      selector("&[data-vertical-align='middle']") { verticalAlign(.middle) }
      selector("&[data-vertical-align='bottom']") { verticalAlign(.bottom) }
      selector("&[data-mono='true']", ".table-cell-mono") { fontFamily(typographyFontMono) }
      selector("&[data-vertical-borders='true']") { borderInlineEnd(borderWidthBase, .solid, borderColorSubtle) }
      selector(".table-cell-selection-input") { cursor(.pointer) }
      selector(".table-selection-container") {
        display(.flex)
        alignItems(.center)
        justifyContent(.center)
      }
      selector(".table-cell-status-icon") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        width(px(22))
        height(px(22))
        borderRadius(borderRadiusCircle)
        color(colorInvertedFixed)
        fontSize(fontSizeXSmall12)
        fontWeight(fontWeightSemiBold)
        lineHeight(1)
      }
      if case .status(_, let bgColor) = type {
        selector(".table-cell-status-icon") { backgroundColor(bgColor) }
      }
    }
  }
}
