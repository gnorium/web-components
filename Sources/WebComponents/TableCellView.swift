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

  @CSSBuilder
  private func cellCSS() -> [CSSOM.CSSRule] {
    padding(spacing8, spacing12)
    verticalAlign(vAlign)

    switch align {
    case .start: textAlign(.left)
    case .center: textAlign(.center)
    case .end: textAlign(.right)
    case .number:
      textAlign(.right)
      fontVariantNumeric(.tabularNums)
    }

    if useMonoFont {
      fontFamily(typographyFontMono)
    } else {
      fontFamily(typographyFontSans)
    }

    fontSize(fontSizeSmall14)
    color(colorBase)
    overflow(.hidden)
    textOverflow(.ellipsis)
    whiteSpace(.nowrap)
    if showVerticalBorders {
      borderInlineEnd(borderWidthBase, .solid, borderColorSubtle)
    }
  }

  @CSSBuilder
  private func statusIconCSS(bgColor: CSS.Color) -> [CSSOM.CSSRule] {
    display(.inlineFlex)
    alignItems(.center)
    justifyContent(.center)
    width(px(22))
    height(px(22))
    borderRadius(borderRadiusCircle)
    backgroundColor(bgColor)
    color(colorInvertedFixed)
    fontSize(fontSizeXSmall12)
    fontWeight(fontWeightSemiBold)
    lineHeight(1)
  }

  public func build() -> DOM.Node {
    td {
      switch type {
      case .text(let text):
        DOM.Text(text)
      case .mono(let text):
        span { text }.style { fontFamily(typographyFontMono) }
      case .selection(let id, let name, let value, let checked):
        div {
          input()
            .type(.radio)
            .id(id)
            .name(name)
            .value(value)
            .checked(checked)
            .style { cursor(.pointer) }
        }
        .class("table-selection-container")
        .style {
          display(.flex)
          alignItems(.center)
          justifyContent(.center)
        }
      case .status(let icon, let bgColor):
        span { icon }.style { statusIconCSS(bgColor: bgColor) }
      case .custom(let nodes):
        div {
          for node in nodes { node }
        }
      }
    }
    .class(stringIsEmpty(`class`) ? "table-cell-view" : "table-cell-view \(`class`)")
    .style { cellCSS() }
  }
}
