import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// A structural component used to arrange data in rows and columns.
public struct TableView: HTMLContent {
  public let captionContent: String
  public let hideCaption: Bool
  public let columns: [Column]
  public let data: [Row]
  public let useRowHeaders: Bool
  public let showVerticalBorders: Bool
  public let selectionMode: SelectionMode?
  public let selectedRows: [String]
  public let sort: Sort?
  public let pending: Bool
  public let paginate: Bool
  public let paginationPosition: PaginationPosition
  public let paginationSizeDefault: Int
  public let headerContent: [Node]
  public let theadContent: [Node]
  public let tbodyContent: [Node]
  public let tfootContent: [Node]
  public let footerContent: [Node]
  public let emptyStateContent: [Node]
  public let theadStyle: @Sendable () -> [CSSRule]
  public let thStyle: @Sendable (Column.Alignment) -> [CSSRule]
  public let tdStyle: @Sendable () -> [CSSRule]
  public let `class`: String

  public struct Column: Sendable {
    public let id: String
    public let label: String
    public let sortable: Bool
    public let align: Alignment
    public let width: LengthPercentage?

    public enum Alignment: Sendable {
      case start
      case center
      case end
      case number

      public var value: String {
        switch self {
        case .start: return "start"
        case .center: return "center"
        case .end: return "end"
        case .number: return "number"
        }
      }
    }

    public init(
      id: String,
      label: String,
      sortable: Bool = true,
      align: Alignment = .start,
      width: LengthPercentage? = nil
    ) {
      self.id = id
      self.label = label
      self.sortable = sortable
      self.align = align
      self.width = width
    }

    public init(
      id: String,
      label: String,
      sortable: Bool = true,
      align: Alignment = .start,
      width: Length
    ) {
      self.init(
        id: id, label: label, sortable: sortable, align: align,
        width: LengthPercentage(width))
    }
  }

  public struct AttributePair: Sendable {
    public let key: String
    public let value: String
    public init(_ key: String, _ value: String) {
      self.key = key
      self.value = value
    }
  }

  public struct NodePair: Sendable {
    public let key: String
    public let value: Node
    public init(_ key: String, _ value: Node) {
      self.key = key
      self.value = value
    }
  }

  public struct Row: Sendable {
    public let id: String?
    public let cells: [NodePair]
    public let groupID: String?  // Groups rows together - first row with groupID becomes collapsible header
    public let isGroupHeader: Bool  // True if this row is a group header (rendered with expand/collapse)
    public let url: String?  // When set, row becomes a navigable link
    public let dataAttributes: [AttributePair]

    public init(
      id: String? = nil,
      cells: [NodePair],
      groupID: String? = nil,
      isGroupHeader: Bool = false,
      url: String? = nil,
      dataAttributes: [AttributePair] = []
    ) {
      self.id = id
      self.cells = cells
      self.groupID = groupID
      self.isGroupHeader = isGroupHeader
      self.url = url
      self.dataAttributes = dataAttributes
    }

    #if SERVER
      public init(
        id: String? = nil,
        cells: [String: String],
        groupID: String? = nil,
        isGroupHeader: Bool = false,
        url: String? = nil,
        dataAttributes: [AttributePair] = []
      ) {
        var nodePairs: [NodePair] = []
        for (key, value) in cells {
          nodePairs.append(NodePair(key, Text(value)))
        }
        self.init(
          id: id,
          cells: nodePairs,
          groupID: groupID,
          isGroupHeader: isGroupHeader,
          url: url,
          dataAttributes: dataAttributes
        )
      }

      public init(
        id: String? = nil,
        cells: [String: Node],
        groupID: String? = nil,
        isGroupHeader: Bool = false,
        url: String? = nil,
        dataAttributes: [AttributePair] = []
      ) {
        var nodePairs: [NodePair] = []
        for (key, value) in cells {
          nodePairs.append(NodePair(key, value))
        }
        self.init(
          id: id,
          cells: nodePairs,
          groupID: groupID,
          isGroupHeader: isGroupHeader,
          url: url,
          dataAttributes: dataAttributes
        )
      }

      public init(_ view: TableRowView) {
        var nodePairs: [NodePair] = []
        for cell in view.cells {
          nodePairs.append(NodePair("unknown", cell.render()))
        }
        self.init(
          id: view.id,
          cells: nodePairs,
          groupID: view.groupID,
          isGroupHeader: view.isGroupHeader,
          url: nil,
          dataAttributes: view.data
        )
      }
    #endif
  }

  public struct Sort: Sendable {
    public let columnID: String
    public let direction: Direction

    public enum Direction: Sendable {
      case ascending
      case descending

      public var value: String {
        switch self {
        case .ascending: return "asc"
        case .descending: return "desc"
        }
      }
    }

    public init(columnID: String, direction: Direction) {
      self.columnID = columnID
      self.direction = direction
    }
  }

  public enum PaginationPosition: Sendable {
    case top
    case bottom
    case both

    public var value: String {
      switch self {
      case .top: return "top"
      case .bottom: return "bottom"
      case .both: return "both"
      }
    }
  }

  /// Selection mode for row selection
  public enum SelectionMode: Sendable {
    /// Multiple selection using checkboxes
    case multiple
    /// Single selection using radio buttons
    case single

    public var value: String {
      switch self {
      case .multiple: return "multiple"
      case .single: return "single"
      }
    }
  }

  public init(
    captionContent: String,
    hideCaption: Bool = false,
    columns: [Column] = [],
    data: [Row] = [],
    useRowHeaders: Bool = false,
    showVerticalBorders: Bool = false,
    selectionMode: SelectionMode? = nil,
    selectedRows: [String] = [],
    sort: Sort? = nil,
    pending: Bool = false,
    paginate: Bool = false,
    paginationPosition: PaginationPosition = .bottom,
    paginationSizeDefault: Int = 10,
    @CSSBuilder theadStyle: @escaping @Sendable () -> [CSSRule] = { [] },
    @CSSBuilder thStyle: @escaping @Sendable (Column.Alignment) -> [CSSRule] = { _ in [] },
    @CSSBuilder tdStyle: @escaping @Sendable () -> [CSSRule] = { [] },
    class: String = "",
    @HTMLBuilder header: () -> [Node] = { [] },
    @HTMLBuilder thead: () -> [Node] = { [] },
    @HTMLBuilder tbody: () -> [Node] = { [] },
    @HTMLBuilder tfoot: () -> [Node] = { [] },
    @HTMLBuilder footer: () -> [Node] = { [] },
    @HTMLBuilder emptyState: () -> [Node] = { [] }
  ) {
    self.captionContent = captionContent
    self.hideCaption = hideCaption
    self.columns = columns
    self.data = data
    self.useRowHeaders = useRowHeaders
    self.showVerticalBorders = showVerticalBorders
    self.selectionMode = selectionMode
    self.selectedRows = selectedRows
    self.sort = sort
    self.pending = pending
    self.paginate = paginate
    self.paginationPosition = paginationPosition
    self.paginationSizeDefault = paginationSizeDefault
    self.theadStyle = theadStyle
    self.thStyle = thStyle
    self.tdStyle = tdStyle
    self.`class` = `class`
    self.headerContent = header()
    self.theadContent = thead()
    self.tbodyContent = tbody()
    self.tfootContent = tfoot()
    self.footerContent = footer()
    self.emptyStateContent = emptyState()
  }

  public func render() -> Node {
    let hasCustomHeader = !headerContent.isEmpty
    let hasCustomThead = !theadContent.isEmpty
    let hasCustomTbody = !tbodyContent.isEmpty
    let hasCustomTfoot = !tfootContent.isEmpty
    let hasFooter = !footerContent.isEmpty
    let hasEmptyState = !emptyStateContent.isEmpty
    let isEmpty = data.isEmpty && !pending

    return div {
      // Header
      if hasCustomHeader || !hideCaption {
        div {
          if hasCustomHeader {
            headerContent
          } else if !hideCaption {
            h2 { captionContent }
              .class("table-header-title")
              .style {
                tableHeaderTitleCSS()
              }
          }
        }
        .class("table-header")
        .style {
          tableHeaderCSS()
        }
      }

      // Pagination (top)
      if paginate && (paginationPosition == .top || paginationPosition == .both) {
        div {
          div {
            "Showing results 1–\(paginationSizeDefault) of \(data.count)"
          }
          .class("pagination-info")
          .style {
            paginationInfoCSS()
          }

          div {
            div {
              ButtonView(label: "First", buttonColor: .gray, weight: .quiet)
            }
            .class("pagination-first")

            div {
              ButtonView(label: "Previous", buttonColor: .gray, weight: .quiet)
            }
            .class("pagination-previous")

            div {
              ButtonView(label: "Next", buttonColor: .gray, weight: .quiet)
            }
            .class("pagination-next")

            div {
              ButtonView(label: "Last", buttonColor: .gray, weight: .quiet)
            }
            .class("pagination-last")
          }
          .class("pagination-controls")
          .style {
            paginationControlsCSS()
          }
        }
        .class("table-pagination table-pagination-top")
        .style {
          tablePaginationCSS()
        }
      }

      // Table wrapper
      div {
        table {
          caption { captionContent }
            .class("table-caption")
            .style {
              tableCaptionCSS(hideCaption)
            }

          // thead
          if hasCustomThead {
            theadContent
          } else {
            thead {
              tr {
                // Select all checkbox (only for multiple selection mode)
                if let mode = selectionMode {
                  th {
                    if mode == .multiple {
                      CheckboxView(
                        id: "select-all",
                        name: "select-all",
                        checked: !selectedRows.isEmpty && selectedRows.count == data.count,
                        indeterminate: !selectedRows.isEmpty && selectedRows.count < data.count,
                        inline: true,
                        hideLabel: true
                      ) {
                        "Select all"
                      }
                    }
                    // For single selection mode, just an empty header cell
                  }
                  .scope(.col)
                  .style {
                    let styles = thStyle(.start)
                    if !styles.isEmpty {
                      styles
                    } else {
                      tableThCSS(.start)
                    }
                  }
                }

                // Column headers
                for column in columns {
                  th {
                    if column.sortable {
                      button {
                        span { column.label }

                        span {
                          AnimatedUpDownChevronView(
                            id: "table-sort-\(column.id)",
                            expanded: {
                              if let currentSort = sort,
                                stringEquals(currentSort.columnID, column.id)
                              {
                                return currentSort.direction == .ascending
                              }
                              return false
                            }(),
                            width: px(12),
                            height: px(12)
                          )
                        }
                        .class("table-sort-icon")
                        .ariaHidden(true)
                        .style {
                          tableSortIconCSS()
                          if stringEquals(sort?.columnID, column.id) {
                            color(.currentColor)
                          } else {
                            display(.none)
                          }
                        }
                      }
                      .class("table-sort-button")
                      .type(.button)
                      .data("column-id", column.id)
                      .style {
                        tableSortButtonCSS()
                      }
                    } else {
                      column.label
                    }
                  }
                  .scope(.col)
                  .style {
                    if let colWidth = column.width {
                      width(colWidth)
                    }
                    let styles = thStyle(column.align)
                    if !styles.isEmpty {
                      styles
                    } else {
                      tableThCSS(column.align)
                    }
                  }
                }
              }
            }
            .class("table-thead")
            .style {
              let styles = theadStyle()
              if !styles.isEmpty {
                styles
              } else {
                tableTheadCSS()
              }
            }
          }

          // tbody
          if hasCustomTbody {
            tbodyContent
          } else {
            tbody {
              if isEmpty && hasEmptyState {
                tr {
                  td {
                    div {
                      emptyStateContent
                    }
                    .class("table-empty-state-content")
                  }
                  .colspan(columns.count + (selectionMode != nil ? 1 : 0))
                  .class("table-empty-state")
                  .style {
                    tableEmptyStateCSS()
                  }
                }
                .class("table-empty-row")
              } else {
                for (rowIndex, row) in data.enumerated() {
                  let rowID = row.id ?? intToString(rowIndex)
                  let isSelected = selectedRows.contains(where: {
                    stringEquals($0, rowID)
                  })
                  var isGroupChild = false
                  if let _ = row.groupID {
                    isGroupChild = !row.isGroupHeader
                  }

                  var hasUrl = false
                  if let _ = row.url {
                    hasUrl = true
                  }

                  var trNode = tr {
                    // Row selection (checkbox for multiple, radio for single)
                    if let mode = selectionMode {
                      td {
                        if mode == .multiple {
                          CheckboxView(
                            id: "row-\(rowID)",
                            name: "row-selection",
                            value: rowID,
                            checked: isSelected,
                            inline: true,
                            hideLabel: true
                          ) {
                            "Select row"
                          }
                        } else {
                          RadioView(
                            id: "row-\(rowID)",
                            name: "row-selection",
                            value: rowID,
                            checked: isSelected,
                            hideLabel: true
                          ) {
                            "Select row"
                          }
                        }
                      }
                      .style {
                        let styles = tdStyle()
                        if !styles.isEmpty {
                          styles
                        } else {
                          tableTdCSS(.start)
                        }
                      }
                    }

                    // Row cells
                    for (cellIndex, column) in columns.enumerated() {
                      let cellContent: Node = row.cells.first(where: { stringEquals($0.key, column.id) })?.value ?? Text("")
                      let isFirstCell = cellIndex == 0

                      if useRowHeaders && isFirstCell {
                        th {
                          // Group header gets animated triangle toggle
                          if row.isGroupHeader, let gid = row.groupID {
                            AnimatedUpDownChevronView(
                              id: "table-group-\(gid)",
                              expanded: false
                            )
                          }
                          // Child rows get indentation
                          if isGroupChild {
                            span { "" }
                              .style {
                                display(.inlineBlock)
                                width(spacing24)
                              }
                          }
                          cellContent
                        }
                        .scope(.row)
                        .style {
                          tableThCSS(column.align)
                          if row.isGroupHeader {
                            fontWeight(fontWeightBold)
                            backgroundColor(backgroundColorNeutralSubtle)
                          }
                        }
                      } else {
                        td {
                          // Group header first cell gets animated triangle toggle
                          if row.isGroupHeader && isFirstCell,
                            let gid = row.groupID
                          {
                            AnimatedUpDownChevronView(
                              id: "table-group-\(gid)",
                              expanded: false
                            )
                          }
                          // Child rows get indentation on first cell
                          if isGroupChild && isFirstCell {
                            span { "" }
                              .style {
                                display(.inlineBlock)
                                width(spacing24)
                              }
                          }
                          if isFirstCell, let url = row.url {
                            a { cellContent }
                              .href(url)
                              .class("table-row-link-anchor")
                          } else {
                            cellContent
                          }
                        }
                        .style {
                          tableTdCSS(column.align)
                          let styles = tdStyle()
                          if !styles.isEmpty {
                            styles
                          }
                          if row.isGroupHeader {
                            fontWeight(fontWeightBold)
                            backgroundColor(backgroundColorNeutralSubtle)
                          }
                        }
                      }
                    }
                  }

                  // Apply standard attributes
                  trNode = trNode
                    .data("row-id", rowID)
                    .data("group-id", row.groupID ?? "")
                    .data("is-group-header", row.isGroupHeader ? "true" : "")
                    .data("url", row.url ?? "")
                    .class(
                      buildRowClass(
                        isSelected: isSelected,
                        isGroupHeader: row.isGroupHeader,
                        isGroupChild: isGroupChild,
                        hasUrl: hasUrl
                      )
                    )

                  // Apply custom data attributes
                  for pair in row.dataAttributes {
                    trNode = trNode.data(pair.key, pair.value)
                  }

                  trNode
                }
              }
            }
            .class("table-tbody")
          }

          // tfoot
          if hasCustomTfoot {
            tfoot {
              tfootContent
            }
            .class("table-tfoot")
            .style {
              tableTfootCSS()
            }
          }
        }
        .class(
          showVerticalBorders ? "table-table table-table-borders-vertical" : "table-table"
        )
        .style {
          tableTableCSS(showVerticalBorders)
        }
      }
      .class("table-wrapper")
      .style {
        tableWrapperCSS()
      }

      // Pagination (bottom)
      if paginate && (paginationPosition == .bottom || paginationPosition == .both) {
        div {
          div {
            "Showing results 1–\(paginationSizeDefault) of \(data.count)"
          }
          .class("pagination-info")
          .style {
            paginationInfoCSS()
          }

          div {
            div {
              ButtonView(label: "First", buttonColor: .gray, weight: .quiet)
            }
            .class("pagination-first")

            div {
              ButtonView(label: "Previous", buttonColor: .gray, weight: .quiet)
            }
            .class("pagination-previous")

            div {
              ButtonView(label: "Next", buttonColor: .gray, weight: .quiet)
            }
            .class("pagination-next")

            div {
              ButtonView(label: "Last", buttonColor: .gray, weight: .quiet)
            }
            .class("pagination-last")
          }
          .class("pagination-controls")
          .style {
            paginationControlsCSS()
          }
        }
        .class("table-pagination table-pagination-bottom")
        .style {
          tablePaginationCSS()
        }
      }

      // Footer
      if hasFooter {
        div {
          footerContent
        }
        .class("table-footer")
        .style {
          tableFooterCSS()
        }
      }
    }
    .class(stringIsEmpty(`class`) ? "table-view\(isEmpty ? " table-view-empty" : "")" : "table-view\(isEmpty ? " table-view-empty" : "") \(`class`)")
    .data("selection-mode", selectionMode?.value ?? "")
    .data("paginate", paginate ? "true" : "false")
    .style {
      tableViewCSS()
    }
  }

  private func buildRowClass(
    isSelected: Bool,
    isGroupHeader: Bool,
    isGroupChild: Bool,
    hasUrl: Bool = false
  ) -> String {
    var classes = ["table-row"]
    if isSelected { classes.append("table-row-selected") }
    if isGroupHeader { classes.append("table-group-header") }
    if isGroupChild { classes.append("table-group-child table-row-animatable") }
    if hasUrl { classes.append("table-row-link") }
    return stringJoin(classes, separator: " ")
  }

  @CSSBuilder
  private func tableViewCSS() -> [CSSRule] {
    width(perc(100))

    // Row styles — applied universally (both auto-generated and custom tbody)
    selector("tbody tr") {
      borderBlockEnd(borderWidthBase, .solid, borderColorSubtle)
    }

    selector("tbody tr:last-child") {
      borderBlockEnd(.none)
    }

    selector("tbody tr:not(.table-empty-row):hover") {
      backgroundColor(backgroundColorInteractiveSubtleHover).important()
    }

    selector("tbody tr:not(.table-empty-row):active") {
      backgroundColor(backgroundColorInteractiveSubtleActive).important()
    }

    selector("tbody tr[data-url]:not([data-url=''])") {
      cursor(cursorBaseHover)
      transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionUser)
    }

    // Disable sort button interaction when table is empty
    selector(".table-view-empty .table-sort-button") {
      cursor(.default).important()
    }

    selector(".table-view-empty .table-sort-button:hover") {
      color(.inherit).important()
    }

    selector(".table-view-empty .table-sort-button:active") {
      color(.inherit).important()
    }

    selector(".table-row-link-anchor") {
      textDecoration(.none)
      color(.inherit)
    }

    // Fixed row height — prevent wrapping, let columns expand and table scroll horizontally
    selector("td", "th") {
      whiteSpace(.nowrap)
    }

    // Animated expand/collapse for group child rows — translate underneath
    selector(".table-row-animatable") {
      transition(.transform, transitionDurationMedium, transitionTimingFunctionSystem)
    }

    selector(".table-row-animatable.table-row-collapsed") {
      transform(translateY(perc(-100)))
    }
  }

  @CSSBuilder
  private func tableHeaderCSS() -> [CSSRule] {
    display(.flex)
    alignItems(.center)
    justifyContent(.spaceBetween)
    gap(spacing12)
    padding(spacing12)
    marginBlockEnd(spacing8)
  }

  @CSSBuilder
  private func tableHeaderTitleCSS() -> [CSSRule] {
    fontFamily(typographyFontSans)
    fontSize(fontSizeLarge18)
    fontWeight(fontWeightBold)
    lineHeight(lineHeightMedium26)
    color(colorBase)
    margin(0)
  }

  @CSSBuilder
  private func tableWrapperCSS() -> [CSSRule] {
    overflowX(.auto)
    border(borderWidthBase, .solid, borderColorSubtle)
    borderRadius(borderRadiusBase)
  }

  @CSSBuilder
  private func tableTableCSS(_ showVerticalBorders: Bool) -> [CSSRule] {
    width(perc(100))
    borderCollapse(.collapse)
    fontFamily(typographyFontSans)
    fontSize(fontSizeMedium16)
    lineHeight(lineHeightMedium26)
    color(colorBase)

    if showVerticalBorders {
      selector("td", "th") {
        borderInlineEnd(borderWidthBase, .solid, borderColorSubtle)
      }

      selector("td:last-child", "th:last-child") {
        borderInlineEnd(.none)
      }
    }
  }

  @CSSBuilder
  private func tableCaptionCSS(_ hideCaption: Bool) -> [CSSRule] {
    fontFamily(typographyFontSans)
    fontSize(fontSizeMedium16)
    fontWeight(fontWeightBold)
    lineHeight(lineHeightMedium26)
    color(colorBase)
    textAlign(.start)
    padding(spacing12)

    if hideCaption {
      position(.absolute)
      width(px(1))
      height(px(1))
      margin(px(-1))
      padding(0)
      overflow(.hidden)
      clip(rect(0, 0, 0, 0))
      whiteSpace(.nowrap)
      borderWidth(0)
    }
  }

  @CSSBuilder
  private func tableTheadCSS() -> [CSSRule] {
    backgroundColor(backgroundColorNeutralSubtle)
    borderBlockEnd(borderWidthBase, .solid, borderColorSubtle)
  }

  @CSSBuilder
  private func tableThCSS(_ align: Column.Alignment) -> [CSSRule] {
    padding(spacing12)
    fontFamily(typographyFontSans)
    fontSize(fontSizeSmall14)
    fontWeight(fontWeightBold)
    lineHeight(lineHeightSmall22)
    color(colorEmphasized)

    switch align {
    case .start:
      textAlign(.start)
    case .center:
      textAlign(.center)
    case .end:
      textAlign(.end)
    case .number:
      textAlign(.end)
    }
    verticalAlign(.middle)
  }

  @CSSBuilder
  private func tableSortButtonCSS() -> [CSSRule] {
    display(.flex)
    alignItems(.center)
    gap(spacing4)
    width(perc(100))
    padding(0)
    backgroundColor(backgroundColorTransparent)
    border(.none)
    fontFamily(.inherit)
    fontSize(.inherit)
    fontWeight(.inherit)
    color(.inherit)
    textAlign(.inherit)
    textTransform(.inherit)
    cursor(cursorBaseHover)
    transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

    pseudoClass(.hover) {
      color(colorBlue).important()
    }

    selector(":hover .table-sort-icon") {
      color(colorBlue).important()
    }

    pseudoClass(.active) {
      color(colorBlueActive).important()
    }

    selector(":active .table-sort-icon") {
      color(colorBlueActive).important()
    }
  }

  @CSSBuilder
  private func tableSortIconCSS() -> [CSSRule] {
    display(.inlineFlex)
    alignItems(.center)
    justifyContent(.center)
    width(sizeIconSmall)
    height(sizeIconSmall)
    fontSize(fontSizeXSmall12)
  }

  @CSSBuilder
  private func tableTdCSS(_ align: Column.Alignment) -> [CSSRule] {
    padding(spacing12)

    switch align {
    case .start:
      textAlign(.start)
    case .center:
      textAlign(.center)
    case .end:
      textAlign(.end)
    case .number:
      textAlign(.end)
    }
    verticalAlign(.middle)
  }

  @CSSBuilder
  private func tableTfootCSS() -> [CSSRule] {
    backgroundColor(backgroundColorNeutralSubtle)
    borderBlockStart(borderWidthBase, .solid, borderColorSubtle)
    fontWeight(fontWeightBold)
  }

  @CSSBuilder
  private func tableEmptyStateCSS() -> [CSSRule] {
    padding(spacing48)
    textAlign(.center)
    color(colorSubtle)
    fontFamily(typographyFontSans)
    fontSize(fontSizeMedium16)
    lineHeight(lineHeightMedium26)
  }

  @CSSBuilder
  private func tableFooterCSS() -> [CSSRule] {
    padding(spacing12)
    marginBlockStart(spacing8)
  }

  @CSSBuilder
  private func tablePaginationCSS() -> [CSSRule] {
    display(.flex)
    alignItems(.center)
    justifyContent(.spaceBetween)
    gap(spacing12)
    padding(spacing12)
    borderBlockStart(borderWidthBase, .solid, borderColorSubtle)
    flexWrap(.wrap)
  }

  @CSSBuilder
  private func paginationInfoCSS() -> [CSSRule] {
    fontFamily(typographyFontSans)
    fontSize(fontSizeSmall14)
    lineHeight(lineHeightSmall22)
    color(colorSubtle)
  }

  @CSSBuilder
  private func paginationControlsCSS() -> [CSSRule] {
    display(.flex)
    alignItems(.center)
    gap(spacing8)
  }
}

#if CLIENT
  import WebAPIs

  private class TableInstance: @unchecked Sendable {
    private var table: Element
    private var selectAllCheckbox: Element?
    private var rowInputs: [Element] = []
    private var sortButtons: [Element] = []
    private var groupHeaders: [Element] = []
    private var paginationFirstBtn: Element?
    private var paginationPrevBtn: Element?
    private var paginationNextBtn: Element?
    private var paginationLastBtn: Element?
    private var selectedRows: [String] = []
    private var collapsedGroups: [String] = []
    private var currentSort: (columnID: String, direction: String)?
    private var currentPage: Int = 1
    private var selectionMode: String = ""

    init(table: Element) {
      self.table = table

      // Get selection mode from data attribute
      if let mode = table.getAttribute("data-selection-mode") {
        selectionMode = mode
      }

      selectAllCheckbox = table.querySelector("#select-all")
      // Query for both checkbox and radio inputs
      rowInputs = Array(table.querySelectorAll("[id^='row-']"))
      sortButtons = Array(table.querySelectorAll(".table-sort-button"))
      groupHeaders = Array(table.querySelectorAll(".table-group-header"))

      // Hydrate all animated chevrons
      AnimatedUpDownChevronFactory.hydrateAll(in: table)

      paginationFirstBtn = table.querySelector(".pagination-first")
      paginationPrevBtn = table.querySelector(".pagination-previous")
      paginationNextBtn = table.querySelector(".pagination-next")
      paginationLastBtn = table.querySelector(".pagination-last")

      bindEvents()
    }

    private func bindEvents() {
      // Select all checkbox (only for multiple selection mode)
      if stringEquals(selectionMode, "multiple") {
        if let selectAll = selectAllCheckbox {
          _ = selectAll.addEventListener(.change) { [self] _ in
            self.toggleSelectAll()
          }
        }
      }

      // Row inputs (checkboxes or radios)
      for input in rowInputs {
        _ = input.addEventListener(.change) { [self] _ in
          self.updateRowSelection()
        }
      }

      // Group header expand/collapse — entire row is clickable
      for header in groupHeaders {
        header.style.cursor(.pointer)
        _ = header.addEventListener(.click) { [self] event in
          // Skip if click originated on interactive elements
          if let target = event.target {
            let tag = target.tagName
            if stringEquals(tag, "INPUT") || stringEquals(tag, "LABEL") || stringEquals(tag, "A") {
              return
            }
          }
          self.toggleGroup(header)
        }
      }

      // Sort buttons
      for button in sortButtons {
        _ = button.addEventListener(.click) { [self] _ in
          guard let columnID = button.getAttribute("data-column-id") else { return }
          self.toggleSort(columnID: columnID)
        }
      }

      // Pagination buttons
      if let firstBtn = paginationFirstBtn {
        _ = firstBtn.addEventListener(.click) { [self] _ in
          self.goToPage(1)
        }
      }

      if let prevBtn = paginationPrevBtn {
        _ = prevBtn.addEventListener(.click) { [self] (event: Event) in
          self.goToPage(self.currentPage - 1)
        }
      }

      if let nextBtn = paginationNextBtn {
        _ = nextBtn.addEventListener(.click) { [self] (event: Event) in
          self.goToPage(self.currentPage + 1)
        }
      }

      if let lastBtn = paginationLastBtn {
        _ = lastBtn.addEventListener(.click) { [self] (event: Event) in
          self.goToPage(10)
        }
      }

      // Row link navigation — click anywhere on row to navigate
      let linkRows = table.querySelectorAll("tr[data-url]:not([data-url=''])")
      for row in linkRows {
        _ = row.addEventListener(.click) { (event: Event) in
          // Skip if click originated on interactive elements
          if let target = event.target {
            let tag = target.tagName
            if stringEquals(tag, "INPUT") || stringEquals(tag, "LABEL")
              || stringEquals(tag, "BUTTON") || stringEquals(tag, "A")
            {
              return
            }
          }
          guard let url = row.getAttribute("data-url") else { return }
          location.href = url
        }
      }
    }

    private func toggleGroup(_ header: Element) {
      guard let groupID = header.getAttribute("data-group-id"), !stringIsEmpty(groupID) else {
        return
      }

      // Check if currently collapsed
      let isCollapsed = collapsedGroups.contains(where: { stringEquals($0, groupID) })

      if isCollapsed {
        // Expand: remove from collapsed list
        collapsedGroups = collapsedGroups.filter { !stringEquals($0, groupID) }
      } else {
        // Collapse: add to collapsed list
        collapsedGroups.append(groupID)
      }

      // Animate child rows
      let childRows = table.querySelectorAll(".table-group-child[data-group-id='\(groupID)']")
      for child in childRows {
        if isCollapsed {
          // Expand: show row first, then animate in via rAF
          child.style.display(.tableRow)
          window.requestAnimationFrame {
            child.classList.remove("table-row-collapsed")
          }
        } else {
          // Collapse: add collapsed class, then hide after animation
          child.classList.add("table-row-collapsed")
          window.setTimeout(250) {
            child.style.display(.none)
          }
        }
      }

      // Animate chevron morph
      AnimatedUpDownChevronFactory.from(element: header)?.morph(toExpanded: isCollapsed)

      // Dispatch group toggle event
      let event = CustomEvent(
        type: "table-group-toggle",
        detail: "\(groupID):\(isCollapsed ? "expanded" : "collapsed")")
      table.dispatchEvent(event)
    }

    private func toggleSelectAll() {
      guard let selectAll = selectAllCheckbox else { return }
      let isChecked = (selectAll as? HTMLInputElement)?.checked ?? false

      for input in rowInputs {
        (input as? HTMLInputElement)?.checked = isChecked
      }

      updateRowSelection()
    }

    private func updateRowSelection() {
      selectedRows = []

      for input in rowInputs {
        if (input as? HTMLInputElement)?.checked == true {
          if let idStr = input.getAttribute(.id) {
            if stringStartsWith(idStr, "row-") {
              let rowID = stringSubstring(idStr, from: 4)
              selectedRows.append(rowID)
            }
          }
        }
      }

      // Update select all checkbox state (only for multiple selection mode)
      if stringEquals(selectionMode, "multiple") {
        if let selectAll = selectAllCheckbox {
          if selectedRows.isEmpty {
            (selectAll as? HTMLInputElement)?.checked = false
            selectAll.indeterminate = false
          } else if selectedRows.count == rowInputs.count {
            (selectAll as? HTMLInputElement)?.checked = true
            selectAll.indeterminate = false
          } else {
            (selectAll as? HTMLInputElement)?.checked = false
            selectAll.indeterminate = true
          }
        }
      }

      // Dispatch selection change event
      let joinedRows = stringJoin(selectedRows, separator: ",")
      let event = CustomEvent(type: "table-selection-change", detail: joinedRows)
      table.dispatchEvent(event)
    }

    private func toggleSort(columnID: String) {
      // Toggle sort direction
      if let current = currentSort, stringEquals(current.columnID, columnID) {
        let newDirection = stringEquals(current.direction, "asc") ? "desc" : "asc"
        currentSort = (columnID, newDirection)
      } else {
        currentSort = (columnID, "asc")
      }

      let isAscending: Bool
      if let current = currentSort {
        isAscending = stringEquals(current.direction, "asc")
      } else {
        isAscending = true
      }

      // Find column index by locating the th with the matching sort button
      let headerCells = Array(table.querySelectorAll("thead th"))
      var columnIndex = -1
      for i in 0..<headerCells.count {
        if headerCells[i].querySelector("[data-column-id='\(columnID)']") != nil {
          columnIndex = i
          break
        }
      }
      guard columnIndex >= 0 else { return }

      // Get tbody and its rows
      guard let tbodyEl = table.querySelector("tbody") else { return }
      let allRows = Array(tbodyEl.querySelectorAll("tr"))
      guard allRows.count > 1 else { return }

      // Build row groups: each group is a top-level row followed by its children.
      // A row is a "child" if it has a group-child class (table-group-child,
      // batch-group-child, or lemma-history-sub-row). Top-level rows are everything else.
      var groups: [(header: Element, children: [Element])] = []
      for row in allRows {
        let classList = row.getAttribute(.class) ?? ""
        let isChild =
          stringContains(classList, "group-child")
          || stringContains(classList, "sub-row")
        if isChild {
          // Attach to the last group
          if !groups.isEmpty {
            groups[groups.count - 1].children.append(row)
          }
        } else {
          groups.append((header: row, children: []))
        }
      }

      guard groups.count > 1 else { return }

      // Sort groups by the header row's cell value
      groups.sort { a, b in
        let cellsA = Array(a.header.querySelectorAll("td, th"))
        let cellsB = Array(b.header.querySelectorAll("td, th"))
        let textA = columnIndex < cellsA.count ? cellsA[columnIndex].textContent : ""
        let textB = columnIndex < cellsB.count ? cellsB[columnIndex].textContent : ""

        let cmp: Int
        if let numA = safeParseInt(textA), let numB = safeParseInt(textB) {
          cmp = numA < numB ? -1 : (numA > numB ? 1 : 0)
        } else {
          cmp = stringCompare(textA, textB)
        }
        return isAscending ? cmp < 0 : cmp > 0
      }

      // Reorder DOM: header then its children, per group
      for group in groups {
        tbodyEl.appendChild(group.header)
        for child in group.children {
          tbodyEl.appendChild(child)
        }
      }

      // Animate sort indicator chevrons — show only on active column
      for btn in sortButtons {
        guard let btnColumnID = btn.getAttribute(data("column-id")) else { continue }
        let isActive = stringEquals(btnColumnID, columnID)

        let icon = btn.querySelector(".table-sort-icon")
        guard let icon = icon else { continue }

        if isActive {
          // Show and animate the chevron morph for the active sort column
          icon.style.display(.inlineFlex)
          icon.style.color(.currentColor)
          if let chevron = AnimatedUpDownChevronFactory.from(element: icon) {
            chevron.morph(toExpanded: !isAscending)
          }
        } else {
          // Hide inactive columns and reset to collapsed (down-pointing)
          icon.style.display(.none)
          if let chevron = AnimatedUpDownChevronFactory.from(element: icon) {
            chevron.setState(expanded: false, animated: false)
          }
        }
      }

      // Dispatch sort event
      let directionStr: String
      if let current = currentSort {
        directionStr = current.direction
      } else {
        directionStr = "asc"
      }
      let sortData = "\(columnID):\(directionStr)"
      let event = CustomEvent(type: "table-sort-change", detail: sortData)
      table.dispatchEvent(event)
    }

    private func goToPage(_ page: Int) {
      guard page > 0 else { return }

      currentPage = page

      // Dispatch page change event
      let event = CustomEvent(type: "table-page-change", detail: intToString(page))
      table.dispatchEvent(event)
    }
  }

  public enum TableFactory {
    public static func createElement(
      captionContent: String,
      hideCaption: Bool = false,
      columns: [TableView.Column] = [],
      data: [TableView.Row] = [],
      useRowHeaders: Bool = false,
      showVerticalBorders: Bool = false,
      selectionMode: TableView.SelectionMode? = nil,
      selectedRows: [String] = [],
      sort: TableView.Sort? = nil,
      pending: Bool = false,
      paginate: Bool = false,
      paginationPosition: TableView.PaginationPosition = .bottom,
      paginationSizeDefault: Int = 10,
      customClass: String = "",
      @HTMLBuilder header: () -> [Node] = { [] },
      @HTMLBuilder thead: () -> [Node] = { [] },
      @HTMLBuilder tbody: () -> [Node] = { [] },
      @HTMLBuilder tfoot: () -> [Node] = { [] },
      @HTMLBuilder footer: () -> [Node] = { [] },
      @HTMLBuilder emptyState: () -> [Node] = { [] }
    ) -> Element {
      let wrapper = document.createElement(.div)
      let view = TableView(
        captionContent: captionContent,
        hideCaption: hideCaption,
        columns: columns,
        data: data,
        useRowHeaders: useRowHeaders,
        showVerticalBorders: showVerticalBorders,
        selectionMode: selectionMode,
        selectedRows: selectedRows,
        sort: sort,
        pending: pending,
        paginate: paginate,
        paginationPosition: paginationPosition,
        paginationSizeDefault: paginationSizeDefault,
        class: customClass,
        header: header,
        thead: thead,
        tbody: tbody,
        tfoot: tfoot,
        footer: footer,
        emptyState: emptyState
      )

      wrapper.innerHTML = buildHTML {
        view.render()
      }

      return wrapper.firstElementChild ?? wrapper
    }
  }

  public class TableHydration: @unchecked Sendable {
    private var instances: [TableInstance] = []

    public init() {
      hydrateAllTables()
    }

    private func hydrateAllTables() {
      let allTables = document.querySelectorAll(".table-view")

      for table in allTables {
        let instance = TableInstance(table: table)
        instances.append(instance)
      }
    }
  }
#endif
