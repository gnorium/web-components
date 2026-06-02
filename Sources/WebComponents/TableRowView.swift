import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A generalized table row that renders a collection of TableCellViews.
public struct TableRowView: HTMLContent {
  public let id: String
  public let cells: [TableCellView]
  public let groupID: String?
  public let isGroupHeader: Bool
  public let isGroupChild: Bool
  public var `class`: String
  public var data: [TableView.AttributePair] = []
  public var style: [(@Sendable () -> [CSSOM.CSSRule])] = []

  public init(
    id: String,
    cells: [TableCellView],
    data: [TableView.AttributePair] = [],
    groupID: String? = nil,
    isGroupHeader: Bool = false,
    isGroupChild: Bool = false,
    class: String = ""
  ) {
    self.id = id
    self.cells = cells
    self.data = data
    self.groupID = groupID
    self.isGroupHeader = isGroupHeader
    self.isGroupChild = isGroupChild
    self.class = `class`
  }

  // MARK: - Modifiers

  public func `class`(_ value: String) -> Self {
    var copy = self
    copy.class = value
    return copy
  }

  public func data(_ key: String, _ value: String) -> Self {
    var copy = self
    copy.data.append(TableView.AttributePair(key, value))
    return copy
  }

  public func style(@CSSBuilder _ rules: @escaping @Sendable () -> [CSSOM.CSSRule]) -> Self {
    var copy = self
    copy.style.append(rules)
    return copy
  }

  @CSSBuilder
  private func rowCSS() -> [CSSOM.CSSRule] {
    borderBottom(px(1), .solid, borderColorSubtle)

    pseudoClass(.hover) {
      backgroundColor(backgroundColorInteractiveSubtleHover)
    }

    if isGroupHeader {
      backgroundColor(backgroundColorNeutralSubtle)
      fontWeight(fontWeightSemiBold)
    }
  }

  public func build() -> DOM.Node {
    var rowNode = tr {
      for cell in cells {
        cell
      }
    }
    .id(id)
    .class(stringIsEmpty(`class`) ? "table-row-view" : "table-row-view \(`class`)")
    .style { rowCSS() }
    .data("row-id", id)

    // Apply dynamic data attributes for WASM hydration
    for attr in data {
      rowNode = rowNode.data(attr.key, attr.value)
    }

    if let gid = groupID {
      rowNode = rowNode.data("group-id", gid)
    }

    // Apply extra data and styles
    for pair in data {
      rowNode = rowNode.data(pair.key, pair.value)
    }

    for s in style {
      rowNode = rowNode.style(s)
    }

    return rowNode
  }
}
