import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import Utilities
import WebTypes

/// A structural component used to arrange data in rows and columns.
public struct TableView: HTMLContent {
  public let captionContent: String
  public let hideCaption: Bool
  public let columns: [Column]
  public let data: [Row]
  public let useRowGroups: Bool
  public let showVerticalBorders: Bool
  public let selectionMode: SelectionMode?
  public let selectedRows: [String]
  public let sort: Sort?
  public let pending: Bool
  public let paginate: Bool
  public let paginationPosition: PaginationPosition
  public let paginationSizeDefault: Int
  public let totalItems: Int?
  public let totalPages: Int?
  public let currentPage: Int?
  public let paginationBaseUrl: String?
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
    public let minWidth: LengthPercentage?

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
      width: LengthPercentage? = nil,
      minWidth: LengthPercentage? = nil
    ) {
      self.id = id
      self.label = label
      self.sortable = sortable
      self.align = align
      self.width = width
      self.minWidth = minWidth
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
    public let customClass: String
    public let dataAttributes: [AttributePair]

    public init(
      id: String? = nil,
      cells: [NodePair],
      groupID: String? = nil,
      isGroupHeader: Bool = false,
      url: String? = nil,
      customClass: String = "",
      dataAttributes: [AttributePair] = []
    ) {
      self.id = id
      self.cells = cells
      self.groupID = groupID
      self.isGroupHeader = isGroupHeader
      self.url = url
      self.customClass = customClass
      self.dataAttributes = dataAttributes
    }

    #if SERVER
      public init(
        id: String? = nil,
        cells: [String: String],
        groupID: String? = nil,
        isGroupHeader: Bool = false,
        url: String? = nil,
        customClass: String = "",
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
          customClass: customClass,
          dataAttributes: dataAttributes
        )
      }

      public init(
        id: String? = nil,
        cells: [String: Node],
        groupID: String? = nil,
        isGroupHeader: Bool = false,
        url: String? = nil,
        customClass: String = "",
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
          customClass: customClass,
          dataAttributes: dataAttributes
        )
      }

      public init(_ view: TableRowView) {
        var nodePairs: [NodePair] = []
        for cell in view.cells {
          nodePairs.append(NodePair(cell.columnID ?? "unknown", cell.build()))
        }
        self.init(
          id: view.id,
          cells: nodePairs,
          groupID: view.groupID,
          isGroupHeader: view.isGroupHeader,
          url: nil,
          customClass: view.class,
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
    useRowGroups: Bool = false,
    showVerticalBorders: Bool = false,
    selectionMode: SelectionMode? = nil,
    selectedRows: [String] = [],
    sort: Sort? = nil,
    pending: Bool = false,
    paginate: Bool = false,
    paginationPosition: PaginationPosition = .bottom,
    paginationSizeDefault: Int = 10,
    totalItems: Int? = nil,
    totalPages: Int? = nil,
    currentPage: Int? = nil,
    paginationBaseUrl: String? = nil,
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
    self.useRowGroups = useRowGroups
    self.showVerticalBorders = showVerticalBorders
    self.selectionMode = selectionMode
    self.selectedRows = selectedRows
    self.sort = sort
    self.pending = pending
    self.paginate = paginate
    self.paginationPosition = paginationPosition
    self.paginationSizeDefault = paginationSizeDefault
    self.totalItems = totalItems
    self.totalPages = totalPages
    self.currentPage = currentPage
    self.paginationBaseUrl = paginationBaseUrl
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

  public func build() -> Node {
    let hasCustomHeader = !headerContent.isEmpty
    let hasCustomThead = !theadContent.isEmpty
    let hasCustomTbody = !tbodyContent.isEmpty
    let hasCustomTfoot = !tfootContent.isEmpty
    let hasFooter = !footerContent.isEmpty
    let hasEmptyState = !emptyStateContent.isEmpty
    let isEmpty = data.isEmpty && !pending

    let computedCurrentPage = currentPage ?? 1
    let computedTotalItems = totalItems ?? data.count
    let computedTotalPages = totalPages ?? (data.isEmpty ? 1 : (data.count + paginationSizeDefault - 1) / paginationSizeDefault)

    let pageNumbers = (1...computedTotalPages).map { pageNum in
      let pageUrl: String
      if let baseUrl = paginationBaseUrl {
        pageUrl = "\(baseUrl)\(pageNum)"
      } else {
        pageUrl = "#"
      }
      return PaginationView.PageNumber(
        label: "\(pageNum)",
        url: pageUrl,
        isActive: pageNum == computedCurrentPage
      )
    }

    let startRange: Int
    let endRange: Int
    if let currentPage = currentPage {
      startRange = data.isEmpty ? 0 : (currentPage - 1) * paginationSizeDefault + 1
      endRange = data.isEmpty ? 0 : min(currentPage * paginationSizeDefault, computedTotalItems)
    } else {
      startRange = data.isEmpty ? 0 : 1
      endRange = data.isEmpty ? 0 : min(paginationSizeDefault, computedTotalItems)
    }
    let sRange = formatNumberWithCommas(startRange)
    let eRange = formatNumberWithCommas(endRange)
    let tItems = formatNumberWithCommas(computedTotalItems)
    let paginationInfo = "Showing results \(sRange)–\(eRange) of \(tItems)"

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
            paginationInfo
          }
          .class("pagination-info")
          .style {
            paginationInfoCSS()
          }

          let prevUrl: String?
          let nextUrl: String?
          if let baseUrl = paginationBaseUrl {
            prevUrl = computedCurrentPage > 1 ? "\(baseUrl)\(computedCurrentPage - 1)" : nil
            nextUrl = computedCurrentPage < computedTotalPages ? "\(baseUrl)\(computedCurrentPage + 1)" : nil
          } else {
            prevUrl = "#"
            nextUrl = "#"
          }

          PaginationView(
            previousUrl: prevUrl,
            nextUrl: nextUrl,
            pageNumbers: pageNumbers,
            class: "table-pagination-controls"
          )
        }
        .class("table-pagination table-pagination-top")
        .style {
          tablePaginationCSS()
        }
      }      // Table wrapper
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
                      div {
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
                      .class("table-selection-container")
                      .style {
                        display(.flex)
                        alignItems(.center)
                        justifyContent(.center)
                      }
                    }

                    // Industry standard column resizer handle
                    div { "" }
                      .class("table-resizer")
                      .style {
                        tableResizerCSS()
                      }
                  }
                  .id("col-selection")
                  .scope(.col)
                  .style {
                    width(px(44))
                    minWidth(px(44))
                    position(.sticky)
                    top(0)
                    zIndex(zIndexSticky).important()
                    backgroundColor(backgroundColorBase).important()
                    tableThCSS(.start)
                    let styles = thStyle(.start)
                    if !styles.isEmpty {
                      styles
                    }
                  }
                }

                // Column headers
                for column in columns {
                  th {
                    if column.sortable {
                      button {
                        span { column.label }
                          .style {
                            overflow(.hidden)
                            textOverflow(.ellipsis)
                            whiteSpace(.nowrap)
                            minWidth(px(0))
                            flexGrow(1)
                            flexShrink(1)
                          }

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
                            width: px(20),
                            height: px(20)
                          )
                        }
                        .class("table-sort-icon")
                        .ariaHidden(true)
                        .style {
                          tableSortIconCSS()
                          if let currentSort = sort, stringEquals(currentSort.columnID, column.id) {
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
                        height(perc(100))
                      }
                    } else {
                      div { column.label }
                        .style {
                          width(perc(100))
                          overflow(.hidden)
                          textOverflow(.ellipsis)
                          whiteSpace(.nowrap)
                          display(.block)
                        }
                    }

                    // Industry standard column resizer handle
                    div { "" }
                      .class("table-resizer")
                      .style {
                        tableResizerCSS()
                      }
                  }
                  .id("col-\(column.id)")
                  .scope(.col)
                  .data("flex", column.width == nil ? "true" : "false")
                  .data("width", column.width != nil ? column.width!.value : "")
                  .style {
                    position(.sticky) // Essential for stickiness and resizer positioning
                    top(0)
                    zIndex(zIndexSticky).important()
                    backgroundColor(backgroundColorBase).important()
                    if let colWidth = column.width {
                      width(colWidth)
                    } else {
                      width(.auto)
                    }
                    if let minW = column.minWidth {
                      minWidth(minW)
                    } else {
                      minWidth(px(150))
                    }
                    
                    tableThCSS(column.align)
                    let styles = thStyle(column.align)
                    if !styles.isEmpty {
                      styles
                    }
                  }
                }

                th { "" }
                  .class("table-th-spacer")
                  .style {
                    position(.sticky)
                    top(0)
                    zIndex(zIndexSticky).important()
                    backgroundColor(backgroundColorBase).important()
                    tableThCSS(.start)
                    borderRightWidth(px(0))
                    padding(px(0))
                    width(px(0))
                    minWidth(px(0))
                  }
              }
            }
            .class("table-thead")
            .style {
              backgroundColor(backgroundColorNeutralSubtle).important()
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
            tbody {
              tbodyContent
            }
            .class("table-tbody")
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
                  .colspan(columns.count + (selectionMode != nil ? 1 : 0) + 1)
                  .class("table-empty-state")
                  .style {
                    tableEmptyStateCSS()
                  }
                }
                .class("table-empty-row")
                .style {
                  backgroundColor(backgroundColorBase).important()
                  borderBlockEnd(borderWidthBase, .solid, borderColorSubtle).important()
                }
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
                        div {
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
                        .class("table-selection-container")
                        .style {
                          display(.flex)
                          alignItems(.center)
                          justifyContent(.center)
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
                      var unwrappedElement: HTMLElement? = nil
                      if let element = cellContent as? HTMLElement, (stringEquals(element.tag, "td") || stringEquals(element.tag, "th")) {
                        if showVerticalBorders {
                          _ = element.style {
                            borderInlineStart(borderWidthBase, .solid, borderColorSubtle)
                          }
                        }
                        if isFirstCell && isGroupChild {
                          element.children.insert(
                            span { "" }
                              .style {
                                display(.inlineBlock)
                                width(spacing24)
                              }.build(), at: 0)
                        }
                        unwrappedElement = element
                      }

                      if let element = unwrappedElement {
                        element
                      } else {
                        if useRowGroups && isFirstCell {
                          th {
                            // Group header gets animated triangle toggle
                            if row.isGroupHeader, let gid = row.groupID {
                              AnimatedUpDownChevronView(
                                id: "table-group-\(gid)",
                                expanded: false,
                                width: px(20),
                                height: px(20)
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
                            }
                          }
                        } else {
                          td {
                            // Child rows get indentation on first cell
                            if isGroupChild && isFirstCell {
                              span { "" }
                                .style {
                                  display(.inlineBlock)
                                  width(spacing24)
                                }
                            }
                            div {
                              if isFirstCell, let url = row.url {
                                a { cellContent }
                                  .href(url)
                                  .class("table-row-link-anchor")
                              } else {
                                cellContent
                              }
                            }
                            .style {
                              width(perc(100))
                              overflow(.hidden)
                              textOverflow(.ellipsis)
                              whiteSpace(.nowrap).important()
                              display(.block)
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
                            }
                          }
                        }
                      }
                    }

                    // Row cells spacer for beautiful edge-to-edge zebra stripe backgrounds
                    td { "" }
                      .class("table-td-spacer")
                      .style {
                        tableTdCSS(.start)
                        borderRightWidth(px(0))
                        padding(px(0))
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
                        hasUrl: hasUrl,
                        customClass: row.customClass
                      )
                    )
                    .style {
                      if isGroupChild || stringContains(row.customClass, "table-row-collapsed") {
                        display(.none)
                      }
                      if rowIndex % 2 == 1 {
                        backgroundColor(backgroundColorNeutralSubtle).important()
                      } else {
                        backgroundColor(backgroundColorBase).important()
                      }
                      if rowIndex == data.count - 1 {
                        borderBlockEnd(.none).important()
                      } else {
                        borderBlockEnd(borderWidthBase, .solid, borderColorSubtle).important()
                      }
                      
                      if hasUrl {
                        cursor(cursorBaseHover)
                        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionUser)
                        pseudoClass(.hover) {
                          backgroundColor(backgroundColorInteractiveSubtleHover).important()
                        }
                        pseudoClass(.active) {
                          backgroundColor(backgroundColorInteractiveSubtleActive).important()
                        }
                      } else {
                        cursor(.default)
                      }
                      
                      // Suppression rules
                      selector(":hover:has(.table-selection-container:hover)", ":active:has(.table-selection-container:active)") {
                        backgroundColor(.transparent).important()
                      }
                      selector(":hover:has(.animated-chevron-container:hover)", ":hover:has(.animated-chevron:hover)") {
                        backgroundColor(.transparent).important()
                      }
                    }

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
      .class("table-inner-wrapper")
      .style {
        tableWrapperCSS(paginate)
        width(perc(100))
      }

      // Pagination (bottom)
      if paginate && (paginationPosition == .bottom || paginationPosition == .both) {
        div {
          div {
            paginationInfo
          }
          .class("pagination-info")
          .style {
            paginationInfoCSS()
          }

          let prevUrl: String?
          let nextUrl: String?
          if let baseUrl = paginationBaseUrl {
            prevUrl = computedCurrentPage > 1 ? "\(baseUrl)\(computedCurrentPage - 1)" : nil
            nextUrl = computedCurrentPage < computedTotalPages ? "\(baseUrl)\(computedCurrentPage + 1)" : nil
          } else {
            prevUrl = "#"
            nextUrl = "#"
          }

          PaginationView(
            previousUrl: prevUrl,
            nextUrl: nextUrl,
            pageNumbers: pageNumbers,
            class: "table-pagination-controls"
          )
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
    .data("paginate-server", {
      if let url = paginationBaseUrl, !stringIsEmpty(url) { return "true" }
      return "false"
    }())
    .data("current-page", intToString(computedCurrentPage))
    .data("pagination-size", intToString(paginationSizeDefault))
    .style {
      tableViewCSS()
    }
  }

  private func buildRowClass(
    isSelected: Bool,
    isGroupHeader: Bool,
    isGroupChild: Bool,
    hasUrl: Bool = false,
    customClass: String = ""
  ) -> String {
    var classes = ["table-row"]
    if isSelected { classes.append("table-row-selected") }
    if isGroupHeader { classes.append("table-group-header") }
    if isGroupChild { classes.append("table-group-child table-row-animatable") }
    if hasUrl { classes.append("table-row-link") }
    if !stringIsEmpty(customClass) { classes.append(customClass) }
    return stringJoin(classes, separator: " ")
  }

  @CSSBuilder
  private func tableViewCSS() -> [CSSRule] {
    width(perc(100))
    display(.flex)
    flexDirection(.column)
    gap(spacing32)

    selector(".table-selection-container input", ".table-selection-container label", ".table-selection-container button") {
      cursor(.pointer).important()
    }

    // Disable interactions when empty or pending
    selector(".table-view-empty tbody tr:hover", ".table-view-pending tbody tr:hover") {
      backgroundColor(.transparent).important()
    }

    selector(".table-view-empty tbody tr:active", ".table-view-pending tbody tr:active") {
      backgroundColor(.transparent).important()
    }

    selector(".table-view-empty .table-row-link", ".table-view-pending .table-row-link", ".table-view-empty tr[data-url]:not([data-url=''])", ".table-view-pending tr[data-url]:not([data-url=''])") {
      cursor(.default).important()
    }

    selector(".table-view-empty .table-sort-button", ".table-view-pending .table-sort-button") {
      cursor(.default).important()
    }

    selector(".table-view-empty .table-sort-button:hover", ".table-view-pending .table-sort-button:hover", ".table-view-empty .table-sort-button:active", ".table-view-pending .table-sort-button:active") {
      color(.inherit).important()
    }

    selector(".table-view-empty .table-sort-button:hover .table-sort-icon", ".table-view-pending .table-sort-button:hover .table-sort-icon") {
      color(.inherit).important()
    }

    selector(".table-view-empty .table-pagination", ".table-view-pending .table-pagination") {
      opacity(0.5)
      pointerEvents(.none)
    }

    selector(".table-row-link-anchor") {
      textDecoration(.none)
      color(.inherit)
    }

    // Level 1 Cell Stacking: Top level rows sit on top of everything
    selector(
      ".table-group-header td",
      ".table-row:not(.table-group-child):not(.table-sub-row):not(.lemma-history-sub-row) td",
      ".table-row-view:not(.table-group-child):not(.table-sub-row):not(.lemma-history-sub-row) td",
      ".table-tbody tr:not(.table-group-child):not(.table-sub-row):not(.lemma-history-sub-row) td"
    ) {
      position(.relative)
      zIndex(zIndexStacking3)
      backgroundColor(.inherit)
    }

    // Level 2 Cell Stacking & Transition
    selector(".table-group-child", ".batch-group-child") {
      transition((.transform, .opacity), transitionDurationMedium, transitionTimingFunctionSystem)
      willChange(.transform, .opacity)
    }
    selector(".table-group-child td", ".batch-group-child td") {
      position(.relative)
      zIndex(zIndexStacking2)
      backgroundColor(.inherit)
    }

    // Level 3 Cell Stacking & Transition
    selector(".lemma-history-sub-row", ".table-sub-row") {
      transition((.transform, .opacity), transitionDurationMedium, transitionTimingFunctionSystem)
      willChange(.transform, .opacity)
    }
    selector(".lemma-history-sub-row td", ".table-sub-row td") {
      position(.relative)
      zIndex(zIndexStacking1)
      backgroundColor(.inherit)
    }

    selector(".table-row-collapsed") {
      pointerEvents(.none)
      opacity(0.0)
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
    color(colorBase)
    margin(0)
  }

  @CSSBuilder
  private func tableWrapperCSS(_ paginate: Bool) -> [CSSRule] {
    position(.relative)
    transform(translateZ(0))
    overflow(.auto)
    border(borderWidthBase, .solid, borderColorSubtle)
    borderRadius(borderRadiusBase)
    backgroundColor(backgroundColorBase)
    if !paginate {
      maxHeight(px(400))
    }
  }

  @CSSBuilder
  private func tableResizerCSS() -> [CSSRule] {
    position(.absolute)
    top(spacing8)
    right(px(-8))
    bottom(spacing8)
    width(px(1))
    padding(0, spacing8)
    boxSizing(.contentBox).important()
    cursor(.colResize)
    zIndex(10)
    userSelect(.none)
    backgroundColor(borderColorSubtle)
    backgroundClip(.contentBox).important()
    transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

    pseudoClass(.hover) {
      backgroundColor(borderColorInteractiveHover)
      opacity(1)
    }

    selector(".resizing") {
      backgroundColor(borderColorInteractiveActive).important()
      opacity(1).important()
    }
  }

  @CSSBuilder
  private func tableTableCSS(_ showVerticalBorders: Bool) -> [CSSRule] {
    tableLayout(.fixed)
    borderCollapse(.separate)
    borderSpacing(0)
    fontFamily(typographyFontSans)
    fontSize(fontSizeMedium16)
    color(colorBase)
    minWidth(perc(100))

    selector(".table-row:nth-child(even)", ".table-row-view:nth-child(even)", ".table-tbody tr:nth-child(even)") {
      backgroundColor(backgroundColorNeutralSubtle)
    }

    selector(".table-row:nth-child(odd)", ".table-row-view:nth-child(odd)", ".table-tbody tr:nth-child(odd)") {
      backgroundColor(backgroundColorBase)
    }

    // Non-clickable rows default
    selector(".table-tbody tr") {
      cursor(.default)
    }

    // Centralized styling for clickable rows
    selector(".table-tbody tr[data-url]:not([data-url=''])", ".table-tbody tr.table-row-link") {
      cursor(cursorBaseHover)
      transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionUser)
    }

    selector(".table-tbody tr[data-url]:not([data-url='']):hover", ".table-tbody tr.table-row-link:hover") {
      backgroundColor(backgroundColorInteractiveSubtleHover).important()
    }

    selector(".table-tbody tr[data-url]:not([data-url='']):active", ".table-tbody tr.table-row-link:active") {
      backgroundColor(backgroundColorInteractiveSubtleActive).important()
    }

    if showVerticalBorders {
      selector("td:last-child", "th:last-child") {
        borderInlineEnd(.none)
      }
    }

    selector(".table-row-link-anchor") {
      color(.inherit)
      textDecoration(.inherit)
      whiteSpace(.inherit)
      textOverflow(.inherit)
      overflow(.inherit)
      display(.block)
      width(perc(100))
    }

    selector("td > div", "th > div", "th > button", "td > span", "th > span") {
      whiteSpace(.nowrap).important()
      textOverflow(.ellipsis).important()
      overflow(.hidden).important()
      display(.block)
      width(perc(100))
    }
  }

  @CSSBuilder
  private func tableCaptionCSS(_ hideCaption: Bool) -> [CSSRule] {
    fontFamily(typographyFontSans)
    fontSize(fontSizeMedium16)
    fontWeight(fontWeightBold)
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
    backgroundColor(.transparent)
    padding(spacing8, spacing12)
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
    overflow(.visible)
    textOverflow(.ellipsis)
    whiteSpace(.nowrap)
    minWidth(0)
    if showVerticalBorders {
      borderInlineStart(borderWidthBase, .solid, borderColorSubtle)
    }
  }

  @CSSBuilder
  private func tableSortButtonCSS() -> [CSSRule] {
    display(.flex)
    alignItems(.center)
    flexShrink(1)
    height(px(26))
    gap(spacing4)
    width(perc(100))
    padding(0)
    backgroundColor(backgroundColorTransparent)
    border(.none)
    fontFamily(.inherit)
    fontSize(.inherit)
    fontWeight(.inherit)
    color(colorBase)
    textAlign(.inherit)
    textTransform(.inherit)
    overflow(.hidden)
    textOverflow(.ellipsis)
    whiteSpace(.nowrap)
    cursor(cursorBaseHover)
    minWidth(0) // Allow flex item to shrink
    transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
  }

  @CSSBuilder
  private func tableSortIconCSS() -> [CSSRule] {
    display(.inlineFlex)
    alignItems(.center)
    justifyContent(.center)
    width(sizeIconMedium)
    height(sizeIconMedium)
    fontSize(fontSizeXSmall12)
    flexShrink(0)
  }

  @CSSBuilder
  private func tableTdCSS(_ align: Column.Alignment) -> [CSSRule] {
    backgroundColor(.inherit)
    padding(spacing8, spacing12)

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
    overflow(.hidden)
    textOverflow(.ellipsis)
    whiteSpace(.nowrap)
    minWidth(0)
    if showVerticalBorders {
      borderInlineStart(borderWidthBase, .solid, borderColorSubtle)
    }
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

  public class TableInstance: @unchecked Sendable {
    public static func updateZebraStriping(for table: Element) {
      let rows = table.querySelectorAll(".table-tbody tr")
      var visibleIndex = 0
      for row in rows {
        let isCollapsed = stringEquals(row.style.getPropertyValue(.display), "none")
        if isCollapsed {
          continue
        }
        if visibleIndex % 2 == 1 {
          row.style.setProperty(.backgroundColor, backgroundColorNeutralSubtle.value, .important)
        } else {
          row.style.setProperty(.backgroundColor, backgroundColorBase.value, .important)
        }
        visibleIndex += 1
      }
    }

    private var table: Element
    private var wrapper: Element
    private var tableTable: Element
    private var selectAllCheckbox: Element?
    private var rowInputs: [Element] = []
    private var sortButtons: [Element] = []
    private var groupHeaders: [Element] = []
    private var paginationPrevBtns: [Element] = []
    private var paginationNextBtns: [Element] = []
    private var paginationPageInputs: [Element] = []
    private var selectedRows: [String] = []
    private var collapsedGroups: [String] = []
    private var expandedSubrowGroups: [String] = []
    private var currentSort: (columnID: String, direction: String)?
    private var currentPage: Int = 1
    private var selectionMode: String = ""
    private var activeResizer: Element?
    private var startX: Double = 0
    private var startWidth: Double = 0
    private var targetTh: Element?
    private var moveListenerID: Int32 = -1
    private var upListenerID: Int32 = -1
    private struct WidthPair {
      let key: String
      var value: Double
    }

    private var startWidths: [WidthPair] = []
    private var dragFloor: Double = 150.0

    private func getStartWidth(for key: String) -> Double? {
      for pair in startWidths {
        if stringEquals(pair.key, key) {
          return pair.value
        }
      }
      return nil
    }

    private func setStartWidth(for key: String, value: Double) {
      for i in 0..<startWidths.count {
        if stringEquals(startWidths[i].key, key) {
          startWidths[i].value = value
          return
        }
      }
      startWidths.append(WidthPair(key: key, value: value))
    }

    private func measureCellContent(_ cell: Element) -> Double {
      let tag = cell.tagName
      let tempCell = document.createElement(tag)
      tempCell.className = cell.className
      
      // Copy inline styles if any exist, but remove active width/min-width constraints
      // to ensure a true, unconstrained, natural content measurement.
      if let styleAttr = cell.getAttribute(.style) {
        tempCell.setAttribute(.style, styleAttr)
        tempCell.style.removeProperty(.width)
        tempCell.style.removeProperty(.minWidth)
        tempCell.style.removeProperty(.maxWidth)
      }
      
      // Enforce unconstrained width, minWidth, and white-space on the cell itself.
      // Critical: the source cell's inline styles include overflow:hidden and existing fixed widths/minWidths
      // which block content shrinking during measurement. We must override them with !important.
      tempCell.style.setProperty(.width, .auto, .important)
      tempCell.style.setProperty(.minWidth, .auto, .important)
      tempCell.style.setProperty(.maxWidth, .none, .important)
      tempCell.style.setProperty(.overflow, .visible, .important)
      tempCell.style.setProperty(.textOverflow, .clip, .important)
      tempCell.style.setProperty(.whiteSpace, .nowrap, .important)
      
      tempCell.innerHTML = cell.innerHTML
      
      // Force all descendant elements inside the measuring cell to size unconstrained,
      // never wrap, and never shrink. This ensures flex layouts, gaps, text, and inline icons
      // are measured natively at their exact, true, unconstrained sizes.
      let descendants = tempCell.querySelectorAll("*")
      for desc in descendants {
        desc.style.setProperty(.overflow, .visible, .important)
        desc.style.setProperty(.textOverflow, .clip, .important)
        desc.style.setProperty(.flexShrink, 0, .important)
        desc.style.setProperty(.whiteSpace, .nowrap, .important)
      }
      
      // Strip name and id attributes from any input elements inside the tempCell.
      // This is critical because radio buttons with the same name are mutually exclusive:
      // when a cloned radio cell is temporarily appended to the DOM for measurement,
      // the browser would deselect the live radio button in the table if they share the same group name.
      let inputs = tempCell.querySelectorAll("input")
      for input in inputs {
        input.removeAttribute("name")
        input.removeAttribute("id")
      }
      
      // Convert the <button> element inside the cloned cell to a plain <div> during measurement.
      // This completely bypasses WebKit's ancient, restrictive layout constraints and user-agent stylesheets
      // applied to `<button>` controls (especially when positioned inside off-screen table cells).
      if let sortButton = tempCell.querySelector(".table-sort-button") {
        let divReplacement = document.createElement(.div)
        divReplacement.className = sortButton.className
        if let styleAttr = sortButton.getAttribute(.style) {
          divReplacement.setAttribute(.style, styleAttr)
        }
        divReplacement.innerHTML = sortButton.innerHTML
        
        if let parent = sortButton.parentElement {
          parent.insertBefore(divReplacement, sortButton)
          sortButton.remove()
        }
        
        // Unconstrain our newly created divReplacement to behave as a standard inline flex container
        divReplacement.style.setProperty(.display, .inlineFlex, .important)
        divReplacement.style.setProperty(.alignItems, .center, .important)
        divReplacement.style.setProperty(.gap, px(4), .important)
        divReplacement.style.setProperty(.width, .auto, .important)
        divReplacement.style.setProperty(.minWidth, .auto, .important)
        divReplacement.style.setProperty(.maxWidth, .none, .important)
        
        // Unconstrain the inner text span inside the replacement div
        if let textSpan = divReplacement.querySelector("span:not(.table-sort-icon)") {
          textSpan.style.setProperty(.display, .inline, .important)
          textSpan.style.setProperty(.width, .auto, .important)
          textSpan.style.setProperty(.minWidth, .auto, .important)
          textSpan.style.setProperty(.maxWidth, .none, .important)
          textSpan.style.setProperty(.flexShrink, 0, .important)
        }
        
        // Force the sort icon span inside the replacement div to have its full, unconstrained dimensions
        if let sortIcon = divReplacement.querySelector(".table-sort-icon") {
          sortIcon.style.setProperty(.display, .inlineFlex, .important)
          sortIcon.style.setProperty(.alignItems, .center, .important)
          sortIcon.style.setProperty(.justifyContent, .center, .important)
          sortIcon.style.setProperty(.width, px(20), .important)
          sortIcon.style.setProperty(.minWidth, px(20), .important)
          sortIcon.style.setProperty(.maxWidth, px(20), .important)
          sortIcon.style.setProperty(.height, px(20), .important)
          sortIcon.style.setProperty(.flexShrink, 0, .important)
          sortIcon.style.setProperty(.marginLeft, 0, .important)
          
          if let svgChild = sortIcon.querySelector("svg") {
            svgChild.style.setProperty(.display, .inlineBlock, .important)
            svgChild.style.setProperty(.width, px(20), .important)
            svgChild.style.setProperty(.minWidth, px(20), .important)
            svgChild.style.setProperty(.maxWidth, px(20), .important)
            svgChild.style.setProperty(.height, px(20), .important)
            svgChild.style.setProperty(.flexShrink, 0, .important)
          }
        }
      }
      
      // Create a hidden measuring table hierarchy that matches the cascade classes
      // of the source table to inherit all typography and padding rules perfectly.
      let measureDiv = document.createElement(.div)
      measureDiv.className = table.className
      if let tableStyle = table.getAttribute(.style) {
        measureDiv.setAttribute(.style, tableStyle)
        measureDiv.style.removeProperty(.width)
        measureDiv.style.removeProperty(.minWidth)
        measureDiv.style.removeProperty(.maxWidth)
      }
      measureDiv.style.setProperty(.position, .absolute, .important)
      measureDiv.style.setProperty(.visibility, .hidden, .important)
      measureDiv.style.setProperty(.top, px(-9999), .important)
      measureDiv.style.setProperty(.left, px(-9999), .important)
      measureDiv.style.setProperty(.width, .auto, .important)
      measureDiv.style.setProperty(.height, .auto, .important)
      
      let tempTable = document.createElement(.table)
      tempTable.className = tableTable.className
      if let tableTableStyle = tableTable.getAttribute(.style) {
        tempTable.setAttribute(.style, tableTableStyle)
        tempTable.style.removeProperty(.width)
        tempTable.style.removeProperty(.minWidth)
        tempTable.style.removeProperty(.maxWidth)
      }
      // Enforce auto layout for measuring table to prevent column compression
      tempTable.style.setProperty(.tableLayout, .auto, .important)
      tempTable.style.setProperty(.width, .auto, .important)
      tempTable.style.setProperty(.display, .table, .important)
      
      let tempSection: Element
      if stringEquals(tag, "th") || stringEquals(tag, "TH") {
        tempSection = document.createElement("thead")
        if let liveThead = table.querySelector("thead") {
          tempSection.className = liveThead.className
          if let liveTheadStyle = liveThead.getAttribute(.style) {
            tempSection.setAttribute(.style, liveTheadStyle)
          }
        }
        tempSection.style.setProperty(.display, .tableHeaderGroup, .important)
      } else {
        tempSection = document.createElement(.tbody)
        if let liveTbody = table.querySelector(".table-tbody") {
          tempSection.className = liveTbody.className
          if let liveTbodyStyle = liveTbody.getAttribute(.style) {
            tempSection.setAttribute(.style, liveTbodyStyle)
          }
        }
        tempSection.style.setProperty(.display, .tableRowGroup, .important)
      }
      
      let tempTr = document.createElement(.tr)
      if let liveTr = cell.parentElement {
        tempTr.className = liveTr.className
        if let liveTrStyle = liveTr.getAttribute(.style) {
          tempTr.setAttribute(.style, liveTrStyle)
        }
      }
      tempTr.style.setProperty(.display, .tableRow, .important)
      
      tempCell.style.setProperty(.display, .tableCell, .important)
      
      tempTr.appendChild(tempCell)
      tempSection.appendChild(tempTr)
      tempTable.appendChild(tempSection)
      measureDiv.appendChild(tempTable)
      
      let parent = table.parentElement ?? document.body
      parent.appendChild(measureDiv)
      let width = tempCell.getBoundingClientRect()?.width ?? 0
      measureDiv.remove()
      
      return width
    }

    private func autoSizeAllColumnsOnMount() {
      let headers = Array(self.table.querySelectorAll("thead th")).filter { !$0.classList.contains("table-th-spacer") }
      guard !headers.isEmpty else { return }
      
      let parentTr = headers[0].parentElement
      let allHeaderCells = parentTr?.querySelectorAll("th") ?? Array<Element>()
      
      for th in headers {
        let colIndex = allHeaderCells.firstIndex(where: { stringEquals($0.idString, th.idString) }) ?? -1
        guard colIndex >= 0 else { continue }
        
        var maxWidth: Double = 0
        
        // Measure the header cell's content
        maxWidth = max(maxWidth, measureCellContent(th))
        
        // Measure body cells at the same column index (only for currently visible rows)
        let bodyRows = table.querySelectorAll(".table-tbody tr")
        for row in bodyRows {
          if row.querySelector("[colspan]") != nil { continue }
          if let rect = row.getBoundingClientRect(), rect.height > 0 {
            let rowCells = row.querySelectorAll(":scope > td, :scope > th")
            if colIndex < rowCells.count {
              let cell = rowCells[colIndex]
              maxWidth = max(maxWidth, measureCellContent(cell))
            }
          }
        }
        
        let finalWidth = ceil(maxWidth)
        let columnFloor = maxWidth >= 150.0 ? 150.0 : finalWidth
        
        // Set the dynamic min-width floor and keep width: auto so they stretch to fill available container space
        th.style.setProperty(.minWidth, px(columnFloor), .important)
        th.style.setProperty(.width, .auto, .important)
      }
    }

    public init(table: Element) {
      self.table = table
      self.wrapper = table.parentElement ?? table
      self.tableTable = table.querySelector(".table-table") ?? table

      // Get selection mode and current page from data attributes
      if let mode = table.getAttribute(data("selection-mode")) {
        selectionMode = mode
      }
      if let pageAttr = table.getAttribute(data("current-page")), let p = parseInt(pageAttr) {
        currentPage = p
      }

      selectAllCheckbox = table.querySelector("#select-all")
      // Query for both checkbox and radio inputs
      rowInputs = Array(table.querySelectorAll("[id^='row-']"))
      sortButtons = Array(table.querySelectorAll(".table-sort-button"))
      groupHeaders = Array(table.querySelectorAll(".table-group-header"))

      // Pre-populate collapsedGroups with any groups that start collapsed (pointing right or data-expanded="false")
      for header in groupHeaders {
        if let groupID = header.getAttribute(data("group-id")), !stringIsEmpty(groupID) {
          if let rightDownChevron = header.querySelector("[data-expanded]") {
            let isExpanded = stringEquals(rightDownChevron.getAttribute(data("expanded")) ?? "true", "true")
            if !isExpanded {
              collapsedGroups.append(groupID)
            }
          } else {
            // Default to collapsed for any AnimatedUpDownChevronView group headers
            collapsedGroups.append(groupID)
          }
        }
      }

      // Hydrate all animated chevrons
      AnimatedUpDownChevronFactory.hydrateAll(in: table)

      paginationPrevBtns = Array(table.querySelectorAll(".pagination-prev"))
      paginationNextBtns = Array(table.querySelectorAll(".pagination-next"))
      paginationPageInputs = Array(table.querySelectorAll(".page-box"))

      bindEvents()
      autoSizeAllColumnsOnMount()
      TableInstance.updateZebraStriping(for: table)

      let isServerPaginated = stringEquals(table.getAttribute(data("paginate-server")) ?? "false", "true")
      if !isServerPaginated {
        self.goToPage(1)
      }
    }

    private func bindEvents() {
      // Column resizing
      let resizers = table.querySelectorAll(".table-resizer")
      for resizer in resizers {
        _ = resizer.addEventListener(.mousedown) { [self] event in
          self.initResize(event, resizer: resizer)
        }
        _ = resizer.addEventListener(.dblclick) { [self] event in
          self.snapResize(event, resizer: resizer)
        }
      }
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

      // Group header expand/collapse — ONLY chevron is clickable
      for header in groupHeaders {
        if let chevron = header.querySelector(".animated-right-down-chevron-view") {
          chevron.style.cursor(.pointer)
          _ = chevron.addEventListener(.click) { [self] _ in
            self.toggleGroup(header)
          }
        }
      }

      // Nested sub-row group expand/collapse — ONLY chevron is clickable
      let subrowToggleRows = Array(table.querySelectorAll(".table-tbody tr:has(.lemma-history-toggle), .table-tbody tr:has(.table-subrow-toggle)"))
      for row in subrowToggleRows {
        if let toggle = row.querySelector(".lemma-history-toggle") ?? row.querySelector(".table-subrow-toggle") {
          toggle.style.cursor(.pointer)
          _ = toggle.addEventListener(.click) { [self] _ in
            if let parentID = row.getAttribute("data-run-id") ?? row.getAttribute("data-subrow-id") {
              self.toggleSubrowGroup(row, parentID: parentID)
            }
          }
        }
      }

      // Sort buttons
      for button in sortButtons {
        _ = button.addEventListener(.click) { [self] _ in
          guard let columnID = button.getAttribute(data("column-id")) else { return }
          self.toggleSort(columnID: columnID)
        }
      }

      let isServerPaginated = stringEquals(table.getAttribute(data("paginate-server")) ?? "false", "true")

      if !isServerPaginated {
        // Pagination buttons
        for prevBtn in paginationPrevBtns {
          _ = prevBtn.addEventListener(.click) { [self] (event: Event) in
            event.preventDefault()
            self.goToPage(self.currentPage - 1)
          }
        }

        for nextBtn in paginationNextBtns {
          _ = nextBtn.addEventListener(.click) { [self] (event: Event) in
            event.preventDefault()
            self.goToPage(self.currentPage + 1)
          }
        }

        for pageInput in paginationPageInputs {
          _ = pageInput.addEventListener(.change) { [self] _ in
            guard let input = pageInput as? HTMLInputElement else { return }
            if let page = parseInt(input.value) {
              self.goToPage(page)
            }
          }
          _ = pageInput.addEventListener(.keydown) { [self] (event: Event) in
            if stringEquals(event.key, "Enter") {
              event.preventDefault()
              guard let input = pageInput as? HTMLInputElement else { return }
              if let page = parseInt(input.value) {
                self.goToPage(page)
              }
            }
          }
        }
      }

      // Row link navigation — click anywhere on row to navigate
      let linkRows = table.querySelectorAll("tr[data-url]:not([data-url=''])")
      for row in linkRows {
        _ = row.addEventListener(.click) { (event: Event) in
          // Skip if click originated on interactive elements
          if let target = event.target {
            let tag = target.tagName
            let container = target.closest(".table-selection-container")
            let isChevron = target.closest(".animated-right-down-chevron-view") != nil || target.closest(".animated-chevron-container") != nil
            
            if stringEquals(tag, "INPUT") || stringEquals(tag, "LABEL")
              || stringEquals(tag, "BUTTON") || stringEquals(tag, "A")
              || container != nil || isChevron
            {
              return
            }
          }
          guard let url = row.getAttribute(data("url")) else { return }
          location.href = url
        }
      }
    }

    private func initResize(_ event: Event, resizer: Element) {
      let mouseEvent = MouseEvent(event)
      activeResizer = resizer
      targetTh = resizer.parentElement
      startX = mouseEvent.clientX
      let currentRect = targetTh?.getBoundingClientRect()
      startWidth = Double(currentRect?.width ?? 0)
      
      targetTh?.setAttribute(data("original-width"), "\(Int(startWidth))")
      
      // Snapshot the starting width of EVERY header in the table to avoid reading
      // getBoundingClientRect() during mouse moves, preventing layout thrashing and width trading.
      startWidths.removeAll()
      let headers = Array(self.table.querySelectorAll("thead th"))
      for header in headers {
        if let id = header.getAttribute(.id), !stringIsEmpty(id) {
          setStartWidth(for: id, value: Double(header.getBoundingClientRect()?.width ?? 0))
        }
      }
      
      // Calculate dynamic floor limit for this manual resize
      let parentTr = targetTh?.parentElement
      let headerCells = parentTr?.querySelectorAll("th") ?? Array<Element>()
      let colIndex = headerCells.firstIndex(where: { stringEquals($0.idString, targetTh?.idString ?? "") }) ?? -1
      
      if colIndex >= 0 {
        var maxWidth: Double = 0
        if let th = targetTh {
          maxWidth = max(maxWidth, measureCellContent(th))
        }
        let bodyRows = table.querySelectorAll(".table-tbody tr:not(.table-group-header)")
        for row in bodyRows {
          if row.querySelector("[colspan]") != nil { continue }
          if let rect = row.getBoundingClientRect(), rect.height > 0 {
            let rowCells = row.querySelectorAll(":scope > td, :scope > th")
            if colIndex < rowCells.count {
              let cell = rowCells[colIndex]
              maxWidth = max(maxWidth, measureCellContent(cell))
            }
          }
        }
        dragFloor = maxWidth >= 150.0 ? 150.0 : maxWidth
      } else {
        dragFloor = 50.0
      }
      
      resizer.classList.add("resizing")
      document.body.style.cursor(.colResize)
      
      moveListenerID = window.addEventListener(.mousemove, onResize)
      upListenerID = window.addEventListener(.mouseup, stopResize)
      
      // Prevent text selection during drag
      mouseEvent.preventDefault()
    }

    private func onResize(_ event: Event) {
      guard let th = targetTh else { return }
      let mouseEvent = MouseEvent(event)
      let delta = mouseEvent.clientX - startX
      let newWidth = max(dragFloor, startWidth + delta)
      
      th.style.setProperty(.width, px(newWidth), .important)
      th.style.setProperty(.minWidth, px(newWidth), .important)
      
      // Update tableTable width to sum of all columns, pinning each column explicitly
      // to prevent table-layout: fixed from redistributing widths during resize.
      let headers = Array(self.table.querySelectorAll("thead th")).filter { !$0.classList.contains("table-th-spacer") }
      let wrapperWidth = Double(self.tableTable.parentElement?.getBoundingClientRect()?.width ?? 0)
      var total: Double = 0
      let activeId = th.getAttribute(.id) ?? ""
      for header in headers {
        let headerId = header.getAttribute(.id) ?? ""
        var w: Double = 0
        if !stringIsEmpty(headerId) && stringEquals(headerId, activeId) {
          w = newWidth
          header.style.setProperty(.width, px(w), .important)
          header.style.setProperty(.minWidth, px(w), .important)
          total += w
        } else {
          let isFlex = stringEquals(header.getAttribute("data-flex") ?? "", "true")
          
          if isFlex {
            header.style.setProperty(.width, .auto, .important)
            header.style.setProperty(.minWidth, px(150), .important)
            total += 150.0
          } else {
            w = getStartWidth(for: headerId) ?? Double(header.getBoundingClientRect()?.width ?? 100)
            header.style.setProperty(.width, px(w), .important)
            header.style.setProperty(.minWidth, px(w), .important)
            total += w
          }
        }
      }
      
      let isNarrower = total < wrapperWidth
      if isNarrower {
        self.tableTable.style.width(perc(100))
        self.tableTable.style.minWidth(perc(100))
      } else {
        self.tableTable.style.width(px(total))
        self.tableTable.style.minWidth(px(total))
      }
    }

    private func snapResize(_ event: Event, resizer: Element) {
      guard let th = resizer.parentElement else { return }
      guard let parentTr = th.parentElement else { return }
      
      // Determine column index of this header cell
      let headerCells = parentTr.querySelectorAll("th")
      let colIndex = headerCells.firstIndex(where: { stringEquals($0.idString, th.idString) }) ?? -1
      guard colIndex >= 0 else { return }
      
      var maxWidth: Double = 0
      
      // Measure the header cell's content
      maxWidth = max(maxWidth, measureCellContent(th))
      
      // Measure body cells at the same column index (only for currently visible rows to prevent hidden content from skewing widths)
      let bodyRows = table.querySelectorAll(".table-tbody tr")
      for row in bodyRows {
        if row.querySelector("[colspan]") != nil { continue }
        if let rect = row.getBoundingClientRect(), rect.height > 0 {
          let rowCells = row.querySelectorAll(":scope > td, :scope > th")
          if colIndex < rowCells.count {
            let cell = rowCells[colIndex]
            maxWidth = max(maxWidth, measureCellContent(cell))
          }
        }
      }
      
      // Set up the snapping finalWidth and min-width floors:
      // For columns with max content width >= 150px, the minimum floor is 150px.
      // For columns with max content width < 150px, there is no floor (it is tight to the natural max content width).
      // We round up to the next integer pixel using ceil() to avoid fractional subpixel rounding truncation in Safari.
      let finalWidth = ceil(maxWidth)
      let columnFloor = maxWidth >= 150.0 ? 150.0 : finalWidth
      
      let headers = Array(self.table.querySelectorAll("thead th")).filter { !$0.classList.contains("table-th-spacer") }
      let wrapperWidth = Double(self.tableTable.parentElement?.getBoundingClientRect()?.width ?? 0)
      
      var total: Double = 0
      let activeId = th.getAttribute(.id) ?? ""
      for header in headers {
        let headerId = header.getAttribute(.id) ?? ""
        if !stringIsEmpty(headerId) && stringEquals(headerId, activeId) {
          header.style.setProperty(.width, px(min(finalWidth, 2000.0)), .important)
          header.style.setProperty(.minWidth, px(min(columnFloor, 2000.0)), .important)
          total += finalWidth
        } else {
          let isFlex = stringEquals(header.getAttribute("data-flex") ?? "", "true")
          if isFlex {
            header.style.setProperty(.width, .auto, .important)
            header.style.setProperty(.minWidth, px(150), .important)
            total += 150.0
          } else {
            let inlineWidthStr = header.style.getPropertyValue("width")
            var w = 150.0
            if !stringIsEmpty(inlineWidthStr) && stringEndsWith(inlineWidthStr, "px") {
              let count = Array(inlineWidthStr.utf8).count
              let valStr = stringSubstring(inlineWidthStr, from: 0, to: count - 2)
              if let val = parseInt(valStr) {
                w = Double(val)
              }
            } else if let attrWidthStr = header.getAttribute(data("width")) {
              if !stringIsEmpty(attrWidthStr) && stringEndsWith(attrWidthStr, "px") {
                let count = Array(attrWidthStr.utf8).count
                let valStr = stringSubstring(attrWidthStr, from: 0, to: count - 2)
                if let val = parseInt(valStr) {
                  w = Double(val)
                }
              }
            }
            header.style.setProperty(.width, px(w), .important)
            header.style.setProperty(.minWidth, px(w), .important)
            total += w
          }
        }
      }
      
      let isNarrower = total < wrapperWidth
      if isNarrower {
        self.tableTable.style.width(perc(100))
        self.tableTable.style.minWidth(perc(100))
      } else {
        self.tableTable.style.width(px(total))
        self.tableTable.style.minWidth(px(total))
      }
    }

    private func stopResize(_ event: Event) {
      activeResizer?.classList.remove("resizing")
      document.body.style.cursor(.default)
      
      if moveListenerID >= 0 {
        window.removeEventListener(.mousemove, moveListenerID)
        moveListenerID = -1
      }
      if upListenerID >= 0 {
        window.removeEventListener(.mouseup, upListenerID)
        upListenerID = -1
      }
      
      activeResizer = nil
      targetTh = nil
    }

    private func toggleGroup(_ header: Element) {
      guard let groupID = header.getAttribute(data("group-id")), !stringIsEmpty(groupID) else {
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
      let childRows = self.table.querySelectorAll(".table-group-child[data-group-id='\(groupID)'], .batch-group-child[data-group-id='\(groupID)']")
      
      if isCollapsed {
        // Expand: show rows first, then let class removal animate slide-in
        for child in childRows {
          child.style.display(.tableRow)
          child.style.removeProperty(.transform)
          child.style.removeProperty(.opacity)
          _ = child.getBoundingClientRect() // Force layout reflow
        }
        TableInstance.updateZebraStriping(for: self.table)
        window.setTimeout(20) {
          for child in childRows {
            child.classList.remove("table-row-collapsed")
          }
        }
      } else {
        // Collapse: add class to trigger hardware-accelerated fade & slide
        for child in childRows {
          child.classList.add("table-row-collapsed")
          
          // Recursively collapse and hide any nested sub-rows belonging to this child row
          if let childRunID = child.getAttribute("data-run-id") {
            let subRows = self.table.querySelectorAll("[data-parent-child-run-id='\(childRunID)'], [data-parent-row-id='\(childRunID)']")
            for subRow in subRows {
              subRow.classList.add("table-row-collapsed")
              subRow.style.display(.none)
            }
            
            // Reset any rotated chevrons inside the child row
            let childChevrons = child.querySelectorAll("[data-expanded='true']")
            for chevron in childChevrons {
              chevron.style.transform(rotate(deg(-90)))
              chevron.setAttribute(data("expanded"), "false")
            }
          }
        }
        
        // After transition completes, hide from layout
        window.setTimeout(250) { [self] in
          for child in childRows {
            if child.classList.contains("table-row-collapsed") {
              child.style.display(.none)
            }
          }
          TableInstance.updateZebraStriping(for: self.table)
        }
      }

      // Morph / rotate chevrons on header generically (supports both SMIL morph up/down and CSS rotate right/down chevrons)
      if let upDownChevron = AnimatedUpDownChevronFactory.from(element: header) {
        upDownChevron.morph(toExpanded: isCollapsed)
      } else if let rightDownChevron = header.querySelector("[data-expanded]") {
        if isCollapsed {
          rightDownChevron.style.transform(rotate(deg(0)))
          rightDownChevron.setAttribute(data("expanded"), "true")
        } else {
          rightDownChevron.style.transform(rotate(deg(-90)))
          rightDownChevron.setAttribute(data("expanded"), "false")
        }
      }

      // Dispatch group toggle event
      let event = CustomEvent(
        type: "table-group-toggle",
        detail: "\(groupID):\(isCollapsed ? "expanded" : "collapsed")")
      self.table.dispatchEvent(event)
    }

    private func toggleSubrowGroup(_ parentRow: Element, parentID: String) {
      let isExpanded = expandedSubrowGroups.contains(where: { stringEquals($0, parentID) })
      
      if isExpanded {
        expandedSubrowGroups = expandedSubrowGroups.filter { !stringEquals($0, parentID) }
      } else {
        expandedSubrowGroups.append(parentID)
      }

      // Query sub-rows generically (supports both Gnorium custom markup and generic subrow patterns)
      let subRows = Array(table.querySelectorAll(".lemma-history-sub-row[data-parent-child-run-id='\(parentID)'], .table-sub-row[data-subrow-parent-id='\(parentID)']"))
      
      if isExpanded {
        // Was expanded, now collapsing → trigger slide up and fade via class
        for subRow in subRows {
          subRow.classList.add("table-row-collapsed")
        }
        window.setTimeout(250) { [self] in
          for subRow in subRows {
            if subRow.classList.contains("table-row-collapsed") {
              subRow.style.display(.none)
            }
          }
          TableInstance.updateZebraStriping(for: self.table)
        }
      } else {
        // Expanding → show first (starting from collapsed opacity/transform), then transition in
        for subRow in subRows {
          subRow.style.display(.tableRow)
          subRow.classList.add("table-row-collapsed")
          subRow.style.removeProperty(.transform)
          subRow.style.removeProperty(.opacity)
          _ = subRow.getBoundingClientRect() // Force layout reflow
        }
        TableInstance.updateZebraStriping(for: self.table)
        
        // Ensure first radio is checked on expand
        var radioToCheck: Element? = nil
        for subRow in subRows {
          if let radio = subRow.querySelector("input[type='radio']") {
            radioToCheck = radio
            break
          }
        }
        if let radio = radioToCheck as? HTMLInputElement {
          radio.checked = true
        }

        window.setTimeout(20) {
          for subRow in subRows {
            subRow.classList.remove("table-row-collapsed")
          }
        }
      }

      // Rotate chevron generically
      let chevronSelector = "[id='lemma-history-\(parentID)-chevron'], [id='subrow-toggle-\(parentID)-chevron'], .lemma-history-toggle, .table-subrow-toggle"
      if let svg = parentRow.querySelector(chevronSelector) {
        if isExpanded {
          svg.style.transform(rotate(deg(-90)))
          svg.setAttribute(data("expanded"), "false")
        } else {
          svg.style.transform(rotate(deg(0)))
          svg.setAttribute(data("expanded"), "true")
        }
      }
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
      self.table.dispatchEvent(event)
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
      let headerCells = Array(self.table.querySelectorAll("thead th"))
      var columnIndex = -1
      for i in 0..<headerCells.count {
        if headerCells[i].querySelector("[data-column-id='\(columnID)']") != nil {
          columnIndex = i
          break
        }
      }
      guard columnIndex >= 0 else { return }

      // Get tbody and its rows
      guard let tbodyEl = self.table.querySelector("tbody") else { return }
      let allRows = Array(tbodyEl.querySelectorAll("tr"))
      guard allRows.count > 1 else { return }

      // Build row groups hierarchically:
      // - A top-level batch group (headerRow: Element, lemmaGroups: [(parentRow: Element, historyRows: [Element])])
      var batchGroups: [(headerRow: Element, lemmaGroups: [(parentRow: Element, historyRows: [Element])])] = []
      
      for row in allRows {
        let classList = row.getAttribute(.class) ?? ""
        let isBatchHeader = stringContains(classList, "table-group-header")
        let isLemmaHistory = stringContains(classList, "lemma-history-sub-row")
        let isBatchChild = stringContains(classList, "batch-group-child")
        
        if isBatchHeader {
          batchGroups.append((headerRow: row, lemmaGroups: []))
        } else if isLemmaHistory {
          if !batchGroups.isEmpty && !batchGroups[batchGroups.count - 1].lemmaGroups.isEmpty {
            let lastBatchIdx = batchGroups.count - 1
            let lastLemmaIdx = batchGroups[lastBatchIdx].lemmaGroups.count - 1
            batchGroups[lastBatchIdx].lemmaGroups[lastLemmaIdx].historyRows.append(row)
          }
        } else if isBatchChild {
          if !batchGroups.isEmpty {
            batchGroups[batchGroups.count - 1].lemmaGroups.append((parentRow: row, historyRows: []))
          }
        } else {
          // Flat row
          batchGroups.append((headerRow: row, lemmaGroups: []))
        }
      }

      // Sort top-level groups (batch headers or flat rows)
      batchGroups.sort { a, b in
        let cellsA = Array(a.headerRow.querySelectorAll(":scope > td, :scope > th"))
        let cellsB = Array(b.headerRow.querySelectorAll(":scope > td, :scope > th"))
        let textA = columnIndex < cellsA.count ? cellsA[columnIndex].textContent : ""
        let textB = columnIndex < cellsB.count ? cellsB[columnIndex].textContent : ""

        let cmp: Int
        if let numA = parseInt(textA), let numB = parseInt(textB) {
          cmp = numA < numB ? -1 : (numA > numB ? 1 : 0)
        } else {
          cmp = stringCompare(textA, textB)
        }
        return isAscending ? cmp < 0 : cmp > 0
      }

      // Sort lemma groups locally inside each batch group
      for i in 0..<batchGroups.count {
        batchGroups[i].lemmaGroups.sort { a, b in
          let cellsA = Array(a.parentRow.querySelectorAll(":scope > td, :scope > th"))
          let cellsB = Array(b.parentRow.querySelectorAll(":scope > td, :scope > th"))
          let textA = columnIndex < cellsA.count ? cellsA[columnIndex].textContent : ""
          let textB = columnIndex < cellsB.count ? cellsB[columnIndex].textContent : ""

          let cmp: Int
          if let numA = parseInt(textA), let numB = parseInt(textB) {
            cmp = numA < numB ? -1 : (numA > numB ? 1 : 0)
          } else {
            cmp = stringCompare(textA, textB)
          }
          return isAscending ? cmp < 0 : cmp > 0
        }
      }

      // Reorder DOM hierarchically
      for bg in batchGroups {
        tbodyEl.appendChild(bg.headerRow)
        for lg in bg.lemmaGroups {
          tbodyEl.appendChild(lg.parentRow)
          for hr in lg.historyRows {
            tbodyEl.appendChild(hr)
          }
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
      self.table.dispatchEvent(event)
      TableInstance.updateZebraStriping(for: self.table)
    }

    private func goToPage(_ page: Int) {
      let isPaginated = stringEquals(table.getAttribute(data("paginate")) ?? "false", "true")
      let sizeStr = table.getAttribute(data("pagination-size")) ?? "10"
      let pageSize = parseInt(sizeStr) ?? 10

      let rows = table.querySelectorAll(".table-tbody tr")
      let dataRows = Array(rows).filter { !$0.classList.contains("table-empty-row") }
      let totalRows = dataRows.count

      let maxPage = totalRows == 0 ? 1 : (totalRows + pageSize - 1) / pageSize

      guard page > 0 && page <= maxPage else { return }

      currentPage = page

      // Sync all pagination inputs
      for pageInput in paginationPageInputs {
        if let input = pageInput as? HTMLInputElement {
          input.value = intToString(page)
        }
      }

      if isPaginated {
        let startIdx = (page - 1) * pageSize
        let endIdx = min(startIdx + pageSize, totalRows)

        for (index, row) in dataRows.enumerated() {
          if index >= startIdx && index < endIdx {
            row.style.setProperty(.display, "table-row", .important)
          } else {
            row.style.setProperty(.display, "none", .important)
          }
        }

        // Update pagination info text: Showing results X–Y of Z
        let infoEls = table.querySelectorAll(".pagination-info")
        let showingStart = totalRows == 0 ? 0 : startIdx + 1
        let infoText = "Showing results \(showingStart)–\(endIdx) of \(totalRows)"
        for infoEl in infoEls {
          infoEl.textContent = infoText
        }
      }

      // Dispatch page change event
      let event = CustomEvent(type: "table-page-change", detail: intToString(page))
      self.table.dispatchEvent(event)
      TableInstance.updateZebraStriping(for: self.table)
    }
  }

  public enum TableFactory {
    public static func createElement(
      captionContent: String,
      hideCaption: Bool = false,
      columns: [TableView.Column] = [],
      data: [TableView.Row] = [],
      useRowGroups: Bool = false,
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
        useRowGroups: useRowGroups,
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

      wrapper.innerHTML = renderHTML {
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
