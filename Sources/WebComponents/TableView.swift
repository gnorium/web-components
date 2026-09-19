import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
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
  /// The size of the pagination control itself. Mini suits a dense table
  /// tucked inside a page; a table that is the page wants the normal one.
  public let paginationControlSize: PaginationView.Size
  public let totalItems: Int?
  public let totalPages: Int?
  public let currentPage: Int?
  public let paginationBaseUrl: String?
  public let headerContent: [DOM.Node]
  public let theadContent: [DOM.Node]
  public let tbodyContent: [DOM.Node]
  public let tfootContent: [DOM.Node]
  public let footerContent: [DOM.Node]
  public let emptyStateContent: [DOM.Node]
  public let theadStyle: @Sendable () -> [CSSOM.CSSRule]
  public let thStyle: @Sendable (Column.Alignment) -> [CSSOM.CSSRule]
  public let tdStyle: @Sendable () -> [CSSOM.CSSRule]
  public let `class`: String

  public struct Column: Sendable {
    public let id: String
    public let label: String
    public let sortable: Bool
    public let align: Alignment
    public let width: CSS.LengthPercentage?
    public let minWidth: CSS.LengthPercentage?

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
      width: CSS.LengthPercentage? = nil,
      minWidth: CSS.LengthPercentage? = nil
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
      width: CSS.Length
    ) {
      self.init(
        id: id, label: label, sortable: sortable, align: align,
        width: CSS.LengthPercentage(width))
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
    public let value: DOM.Node
    public init(_ key: String, _ value: DOM.Node) {
      self.key = key
      self.value = value
    }
  }

  /// The words a cell shows, however it is built — a bare string, a link, a
  /// chip. Used for the cell's title, so an ellipsis never hides a value.
  static func plainText(of node: DOM.Node) -> String {
    if let text = node as? DOM.Text { return text.content }
    guard let element = node as? DOM.Element else { return "" }
    var parts: [String] = []
    for child in element.children {
      let text = plainText(of: child)
      if !stringIsEmpty(text) { parts.append(text) }
    }
    return stringJoin(parts, separator: " ")
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
          nodePairs.append(NodePair(key, DOM.Text(value)))
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
        cells: [String: DOM.Node],
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
    paginationControlSize: PaginationView.Size = .mini,
    totalItems: Int? = nil,
    totalPages: Int? = nil,
    currentPage: Int? = nil,
    paginationBaseUrl: String? = nil,
    @CSSBuilder theadStyle: @escaping @Sendable () -> [CSSOM.CSSRule] = { [] },
    @CSSBuilder thStyle: @escaping @Sendable (Column.Alignment) -> [CSSOM.CSSRule] = { _ in [] },
    @CSSBuilder tdStyle: @escaping @Sendable () -> [CSSOM.CSSRule] = { [] },
    class: String = "",
    @HTMLBuilder header: () -> [DOM.Node] = { [] },
    @HTMLBuilder thead: () -> [DOM.Node] = { [] },
    @HTMLBuilder tbody: () -> [DOM.Node] = { [] },
    @HTMLBuilder tfoot: () -> [DOM.Node] = { [] },
    @HTMLBuilder footer: () -> [DOM.Node] = { [] },
    @HTMLBuilder emptyState: () -> [DOM.Node] = { [] }
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
    self.paginationControlSize = paginationControlSize
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

  public func build() -> DOM.Node {
    let hasCustomHeader = !headerContent.isEmpty
    let hasCustomThead = !theadContent.isEmpty
    let hasCustomTbody = !tbodyContent.isEmpty
    let hasCustomTfoot = !tfootContent.isEmpty
    let hasFooter = !footerContent.isEmpty
    let hasEmptyState = !emptyStateContent.isEmpty
    // Custom tbody supplies its own rows (data often stays []) — not an empty table.
    let isEmpty = data.isEmpty && !pending && !hasCustomTbody

    let computedCurrentPage = currentPage ?? 1
    // A grouped table pages by what a reader counts — the parent rows. Counting
    // every row made one specimen with 413 runs read as "1–25 of 414", and the
    // first page was mostly that specimen's own children.
    let topLevelCount = data.filter { $0.groupID == nil || $0.isGroupHeader }.count
    let computedTotalItems = totalItems ?? topLevelCount
    let computedTotalPages =
      totalPages
      ?? (topLevelCount == 0 ? 1 : (topLevelCount + paginationSizeDefault - 1) / paginationSizeDefault)

    let pageNumbers: [PaginationView.PageNumber]
    if computedTotalPages <= 10 {
      pageNumbers = (1...computedTotalPages).map { pageNum in
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
    } else {
      var pages: [Int] = []
      pages.append(1)
      if computedCurrentPage > 7 { pages.append(-1) }
      let rangeStart = max(2, computedCurrentPage - 5)
      let rangeEnd = min(computedTotalPages - 1, computedCurrentPage + 5)
      for i in rangeStart...rangeEnd { pages.append(i) }
      if computedCurrentPage < computedTotalPages - 6 { pages.append(-1) }
      if computedTotalPages > 1 { pages.append(computedTotalPages) }
      pageNumbers = pages.map { pageNum in
        let pageUrl: String
        if let baseUrl = paginationBaseUrl {
          pageUrl = "\(baseUrl)\(max(pageNum, 1))"
        } else {
          pageUrl = "#"
        }
        return PaginationView.PageNumber(
          label: pageNum < 0 ? "..." : "\(pageNum)",
          url: pageNum < 0 ? "#" : pageUrl,
          isActive: pageNum == computedCurrentPage
        )
      }
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
          }
        }
        .class("table-header")
      }

      // Pagination (top)
      if paginate && (paginationPosition == .top || paginationPosition == .both) {
        div {
          div {
            paginationInfo
          }
          .class("pagination-info")

          let prevUrl: String?
          let nextUrl: String?
          if let baseUrl = paginationBaseUrl {
            prevUrl = computedCurrentPage > 1 ? "\(baseUrl)\(computedCurrentPage - 1)" : nil
            nextUrl = computedCurrentPage < computedTotalPages ? "\(baseUrl)\(computedCurrentPage + 1)" : nil
          } else {
            prevUrl = computedCurrentPage > 1 ? "#" : nil
            nextUrl = computedCurrentPage < computedTotalPages ? "#" : nil
          }

          PaginationView(
            totalPages: computedTotalPages,
            previousUrl: prevUrl,
            nextUrl: nextUrl,
            pageNumbers: pageNumbers,
            size: paginationControlSize,
            class: "table-pagination-controls"
          )
        }
        .class("table-pagination table-pagination-top")
      }      // Table wrapper
      div {
        // The box owns the border; this owns the scrolling. A scrollbar is
        // drawn inside its own element's edge, so when the bordered box
        // scrolled, the bar lay across the bottom border and cut through
        // both rounded corners.
        div {
          table {
            // Column geometry belongs to the table model. Runtime resizing updates
            // these standard HTML width attributes rather than element styles.
            colgroup {
              if selectionMode != nil {
                col()
                  .id("table-col-selection")
                  .setAttribute("width", "44")
              }
              for column in columns {
                var columnElement = col().data("table-column-id", column.id)
                if let width = column.width {
                  columnElement = columnElement.setAttribute("width", width.value)
                }
                columnElement
              }
              col()
                .id("table-col-spacer")
                .setAttribute("width", "16")
            }

            caption { captionContent }
              .class("table-caption")
              .data("hidden", hideCaption)

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
                      }

                      // Industry standard column resizer handle
                      div { "" }
                        .class("table-resizer")
                    }
                .id("col-selection")
                .scope(.col)
                    .data("table-column-id", "selection")
                    .data("align", "start")
                    .class("table-selection-header")
                    .style {
                      selector("&") {
                        let styles = thStyle(.start)
                        if !styles.isEmpty {
                          styles
                        }
                      }
                    }
                  }

                  // Column headers
                  for column in columns {
                    th {
                      if column.sortable {
                        button {
                          span { column.label }
                            .class("table-sort-label")

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
                          .data("active", sort.map { stringEquals($0.columnID, column.id) } ?? false)
                        }
                        .class("table-sort-button")
                        .type(.button)
                        .data("column-id", column.id)
                      } else {
                        div { column.label }
                          .class("table-header-label")
                      }

                      // Industry standard column resizer handle
                      div { "" }
                        .class("table-resizer")
                    }
                    .id("col-\(column.id)")
                    .scope(.col)
                    .data("table-column-id", column.id)
                    .data("align", column.align.value)
                    .data("flex", column.width == nil ? "true" : "false")
                    .data("width", column.width != nil ? column.width!.value : "")
                    .class("table-column-header")
                    .style {
                      selector("&") {
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
                        let styles = thStyle(column.align)
                        if !styles.isEmpty {
                          styles
                        }
                      }
                    }
                  }

                  th { "" }
                    .class("table-th-spacer")
                }
              }
              .class("table-thead")
              .style {
                selector("&") { theadStyle() }
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
                        }
                        .style {
                          selector("&") {
                            let styles = tdStyle()
                            if !styles.isEmpty {
                              styles
                            }
                          }
                        }
                      }

                      // Row cells
                      for (cellIndex, column) in columns.enumerated() {
                        let cellContent: DOM.Node = row.cells.first(where: { stringEquals($0.key, column.id) })?.value ?? DOM.Text("")
                        let isFirstCell = cellIndex == 0
                        // A cell is one line and clips with an ellipsis, so the
                        // value it holds is also its title: hovering shows the
                        // whole of it rather than leaving the reader to guess.
                        // Links carry their own text down the tree, and a title
                        // is most wanted precisely where a long one is clipped.
                        let cellTitle = TableView.plainText(of: cellContent)
                        var unwrappedElement: HTML.HTMLElement? = nil
                        if let element = cellContent as? HTML.HTMLElement, (stringEquals(element.tag, "td") || stringEquals(element.tag, "th")) {
                          if isFirstCell && isGroupChild {
                            element.children.insert(
                              span { "" }
                                .class("table-group-indent").build(), at: 0)
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
                                AnimatedRightDownChevronView(
                                  id: "table-group-\(gid)",
                                  expanded: false,
                                  width: px(20),
                                  height: px(20)
                                )
                              }
                              // Child rows get indentation
                              if isGroupChild {
                                span { "" }
                                  .class("table-group-indent")
                              }
                              cellContent
                            }
                            .scope(.row)
                            .data("align", column.align.value)
                          } else {
                            td {
                              // Child rows get indentation on first cell
                              if isGroupChild && isFirstCell {
                                span { "" }
                                  .class("table-group-indent")
                              }
                              div {
                                if isFirstCell, let url = row.url {
                                  LinkView(url: url) {
                                    cellContent
                                  }
                                } else {
                                  cellContent
                                }
                              }
                              .class("table-cell-content")
                            }
                            .data("align", column.align.value)
                            .title(cellTitle)
                            .style {
                              selector("&") {
                                let styles = tdStyle()
                                if !styles.isEmpty {
                                  styles
                                }
                              }
                            }
                          }
                        }
                      }

                      // Row cells spacer for beautiful edge-to-edge zebra stripe backgrounds
                      td { "" }
                        .class("table-td-spacer")
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
                          isLast: rowIndex == data.count - 1,
                          isEven: rowIndex % 2 == 1,
                          isInitiallyCollapsed: isGroupChild || stringContains(row.customClass, "table-row-collapsed"),
                          customClass: row.customClass
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
            }
          }
          .class(
            showVerticalBorders ? "table-table table-table-borders-vertical" : "table-table"
          )
        }
        .class("table-scroll")
      }
      .class("table-inner-wrapper")

      // Pagination (bottom)
      if paginate && (paginationPosition == .bottom || paginationPosition == .both) {
        div {
          div {
            paginationInfo
          }
          .class("pagination-info")

          let prevUrl: String?
          let nextUrl: String?
          if let baseUrl = paginationBaseUrl {
            prevUrl = computedCurrentPage > 1 ? "\(baseUrl)\(computedCurrentPage - 1)" : nil
            nextUrl = computedCurrentPage < computedTotalPages ? "\(baseUrl)\(computedCurrentPage + 1)" : nil
          } else {
            prevUrl = computedCurrentPage > 1 ? "#" : nil
            nextUrl = computedCurrentPage < computedTotalPages ? "#" : nil
          }

          PaginationView(
            totalPages: computedTotalPages,
            previousUrl: prevUrl,
            nextUrl: nextUrl,
            pageNumbers: pageNumbers,
            size: paginationControlSize,
            class: "table-pagination-controls"
          )
        }
        .class("table-pagination table-pagination-bottom")
      }

      // Footer
      if hasFooter {
        div {
          footerContent
        }
        .class("table-footer")
      }
    }
    .class(stringIsEmpty(`class`) ? "table-view\(isEmpty ? " table-view-empty" : "")\(pending ? " table-view-pending" : "")" : "table-view\(isEmpty ? " table-view-empty" : "")\(pending ? " table-view-pending" : "") \(`class`)")
    .data("selection-mode", selectionMode?.value ?? "")
    .data("paginate", paginate ? "true" : "false")
    .data("paginate-server", {
      if let url = paginationBaseUrl, !stringIsEmpty(url) { return "true" }
      return "false"
    }())
    .data("current-page", intToString(computedCurrentPage))
    .data("pagination-size", intToString(paginationSizeDefault))
    .data("total-items", intToString(computedTotalItems))
    .data("pagination-base-url", paginationBaseUrl ?? "")
    .data("sort-column", sort?.columnID ?? "")
    .data("sort-order", sort?.direction.value ?? "")
    .style {
      selector("&") {
        width(perc(100))
        display(.flex)
        flexDirection(.column)
        gap(spacing16)
        flex(1)
        minHeight(0)
      }
      selector("&.table-view-empty tbody tr:hover", "&.table-view-pending tbody tr:hover") { backgroundColor(.transparent).important() }
      selector("&.table-view-empty tbody tr:active", "&.table-view-pending tbody tr:active") { backgroundColor(.transparent).important() }
      selector("&.table-view-empty .table-row-link", "&.table-view-pending .table-row-link", "&.table-view-empty tr[data-url]:not([data-url=''])", "&.table-view-pending tr[data-url]:not([data-url=''])") { cursor(.default).important() }
      selector("&.table-view-empty .table-sort-button", "&.table-view-pending .table-sort-button") { cursor(.default).important() }
      selector("&.table-view-empty .table-sort-button:hover", "&.table-view-pending .table-sort-button:hover", "&.table-view-empty .table-sort-button:active", "&.table-view-pending .table-sort-button:active") { color(.inherit).important() }
      selector("&.table-view-empty .table-sort-button:hover .table-sort-icon", "&.table-view-pending .table-sort-button:hover .table-sort-icon") { color(.inherit).important() }
      selector("&.table-view-empty .table-pagination", "&.table-view-pending .table-pagination") {
        opacity(0.5)
        pointerEvents(.none)
      }
      selector("& .table-group-header td", "& .table-row:not(.table-group-child):not(.table-sub-row):not(.lemma-history-sub-row) td", "& .table-row-view:not(.table-group-child):not(.table-sub-row):not(.lemma-history-sub-row) td", "& .table-tbody tr:not(.table-group-child):not(.table-sub-row):not(.lemma-history-sub-row) td") {
        position(.relative)
        zIndex(zIndexStacking3)
        backgroundColor(.inherit)
      }
      selector("& .table-group-child", "& .batch-group-child") {
        transition((.transform, .opacity), transitionDurationMedium, transitionTimingFunctionSystem)
        willChange(.transform, .opacity)
      }
      selector("& .table-group-child td", "& .batch-group-child td") {
        position(.relative)
        zIndex(zIndexStacking2)
        backgroundColor(.inherit)
      }
      selector("& .lemma-history-sub-row", "& .table-sub-row") {
        transition((.transform, .opacity), transitionDurationMedium, transitionTimingFunctionSystem)
        willChange(.transform, .opacity)
      }
      selector("& .lemma-history-sub-row td", "& .table-sub-row td") {
        position(.relative)
        zIndex(zIndexStacking1)
        backgroundColor(.inherit)
      }
      descendant(".table-row-collapsed") {
        pointerEvents(.none)
        opacity(0)
        transform(translateY(perc(-100)))
      }
      descendant(".table-row-hidden") { display(.none).important() }
      descendant(".table-sort-icon[data-active='false']") { display(.none) }
      descendant(".table-sort-icon[data-active='true']") {
        display(.inlineFlex)
        color(.currentColor)
      }
      selector("& .table-group-header .animated-right-down-chevron-view", "& .lemma-history-toggle", "& .table-subrow-toggle") { cursor(.pointer) }
      selector("&.table-measure-root") {
        position(.absolute).important()
        visibility(.hidden).important()
        top(px(-9999)).important()
        left(px(-9999)).important()
        width(.auto).important()
        height(.auto).important()
      }
      descendant(".table-measure-table") {
        tableLayout(.auto).important()
        width(.auto).important()
        display(.table).important()
      }
      descendant(".table-measure-cell") {
        display(.tableCell).important()
        width(.auto).important()
        minWidth(.auto).important()
        maxWidth(.none).important()
        overflow(.visible).important()
        textOverflow(.clip).important()
        whiteSpace(.nowrap).important()
      }
      selector("& .table-measure-cell *") {
        overflow(.visible).important()
        textOverflow(.clip).important()
        flexShrink(0).important()
        whiteSpace(.nowrap).important()
      }
      descendant(".table-measure-sort-button") {
        display(.inlineFlex).important()
        alignItems(.center).important()
        gap(px(4)).important()
        width(.auto).important()
        minWidth(.auto).important()
        maxWidth(.none).important()
      }
      selector("& .table-measure-sort-button span:not(.table-sort-icon)") {
        display(.inline).important()
        width(.auto).important()
        minWidth(.auto).important()
        maxWidth(.none).important()
        flexShrink(0).important()
      }
      selector("& .table-measure-sort-button .table-sort-icon", "& .table-measure-sort-button .table-sort-icon svg") {
        display(.inlineFlex).important()
        width(px(20)).important()
        minWidth(px(20)).important()
        maxWidth(px(20)).important()
        height(px(20)).important()
        flexShrink(0).important()
      }
      selector("& .table-measure-sort-button .table-sort-icon") {
        alignItems(.center).important()
        justifyContent(.center).important()
        marginLeft(0).important()
      }
      descendant(".table-header") {
        display(.flex)
        alignItems(.center)
        justifyContent(.spaceBetween)
        gap(spacing12)
        padding(spacing12)
      }
      descendant(".table-header-title") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeLarge18)
        fontWeight(fontWeightBold)
        color(colorBase)
        margin(0)
      }
      descendant(".pagination-info") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeSmall14)
        lineHeight(lineHeightSmall22)
        color(colorBase)
      }
      descendant(".table-pagination") {
        display(.flex)
        alignItems(.center)
        justifyContent(.spaceBetween)
        gap(spacing12)
        flexWrap(.wrap)
      }
      descendant(".table-pagination-controls") {
        flexShrink(0)
        // PaginationView centres itself with `margin: 0 auto`. Inside a table
        // footer it is one end of a space-between row, so the end margin has
        // to be taken back or the auto pair recentres it mid-row.
        marginInlineStart(.auto)
        marginInlineEnd(0)
        media(maxWidth(maxWidthBreakpointMobile)) {
          marginInlineStart(0)
        }
      }
      descendant(".table-caption") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightBold)
        color(colorBase)
        textAlign(.start)
        padding(spacing12)
      }
      descendant(".table-caption[data-hidden='true']") {
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
      descendant(".table-inner-wrapper") {
        position(.relative)
        transform(translateZ(0))
        overflow(.hidden)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        backgroundColor(backgroundColorBase)
        width(perc(100))
        display(.flex)
        flex(1)
        minHeight(0)
      }
      descendant(".table-scroll") {
        overflow(.auto)
        // The same curve as the box it sits in, so the bar's ends are clipped
        // by the corners instead of squaring them off.
        borderRadius(borderRadiusBase)
        width(perc(100))
        display(.flex)
        flex(1)
        minWidth(0)
        minHeight(0)
      }
      selector("&.table-view-empty .table-inner-wrapper") {
        minHeight(px(160))
        flexShrink(0)
      }
      selector("& .table-scroll::-webkit-scrollbar-track", "& .table-scroll::-webkit-scrollbar-track-piece", "& .table-scroll::-webkit-scrollbar-corner") {
        backgroundColor(.transparent).important()
      }
      descendant(".table-table") {
        tableLayout(.fixed)
        borderCollapse(.separate)
        borderSpacing(0)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        color(colorBase)
        width(perc(100))
      }
      selector("&.table-view-empty .table-table") {
        display(.flex)
        flexDirection(.column)
        flex(1)
      }
      selector("& .table-row:nth-child(even)", "& .table-row-view:nth-child(even)", "& .table-tbody tr:nth-child(even)") { backgroundColor(backgroundColorNeutralSubtle) }
      selector("& .table-row:nth-child(odd)", "& .table-row-view:nth-child(odd)", "& .table-tbody tr:nth-child(odd)") { backgroundColor(backgroundColorBase) }
      descendant(".table-row-even") { backgroundColor(backgroundColorNeutralSubtle).important() }
      descendant(".table-row-odd") { backgroundColor(backgroundColorBase).important() }
      descendant(".table-row-last") { borderBlockEnd(.none).important() }
      descendant(".table-td-spacer") {
        backgroundColor(.inherit).important()
        width(px(16)).important()
        minWidth(px(16)).important()
        borderRightWidth(0).important()
        padding(0).important()
      }
      descendant(".table-tbody tr") { cursor(.default) }
      selector("& .table-tbody tr[data-url]:not([data-url=''])", "& .table-tbody tr.table-row-link") {
        cursor(cursorBaseHover)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionUser)
      }
      selector("& .table-tbody tr[data-url]:not([data-url='']):hover", "& .table-tbody tr.table-row-link:hover") { backgroundColor(backgroundColorInteractiveSubtleHover).important() }
      selector("& .table-tbody tr[data-url]:not([data-url='']):active", "& .table-tbody tr.table-row-link:active") { backgroundColor(backgroundColorInteractiveSubtleActive).important() }
      selector("& .table-tbody tr:hover:has(.table-selection-container:hover)", "& .table-tbody tr:active:has(.table-selection-container:active)", "& .table-tbody tr:hover:has(.animated-chevron-container:hover)", "& .table-tbody tr:hover:has(.animated-chevron:hover)") {
        backgroundColor(.transparent).important()
      }
      selector("& .table-table-borders-vertical td:last-child", "& .table-table-borders-vertical th:last-child") { borderInlineEnd(.none) }
      selector("& .table-table td > div:not(.table-resizer)", "& .table-table th > div:not(.table-resizer)", "& .table-table th > button", "& .table-table td > span", "& .table-table th > span") {
        whiteSpace(.nowrap).important()
        textOverflow(.ellipsis).important()
        overflow(.hidden).important()
        display(.block)
        width(perc(100))
      }
      descendant(".table-thead") {
        backgroundColor(backgroundColorNeutralSubtle)
        borderBlockEnd(borderWidthBase, .solid, borderColorBase)
        height(px(44))
        minHeight(px(44))
        maxHeight(px(44))
      }
      descendant(".table-tfoot") {
        backgroundColor(backgroundColorNeutralSubtle)
        borderBlockStart(borderWidthBase, .solid, borderColorBase)
        fontWeight(fontWeightBold)
      }
      selector("& .table-thead th", "& .table-tbody th") {
        backgroundColor(.inherit)
        padding(spacing8, spacing12)
        fontFamily(typographyFontSans)
        fontSize(fontSizeSmall14)
        fontWeight(fontWeightBold)
        lineHeight(lineHeightSmall22)
        color(colorEmphasized)
        height(px(44))
        minHeight(px(44))
        maxHeight(px(44))
        boxSizing(.borderBox)
        verticalAlign(.middle)
        overflow(.visible)
        whiteSpace(.nowrap)
        // A header is the column's name; a name shortened to "Atte…" is no
        // name. `max-content` keeps the column at least as wide as its label,
        // whatever width the caller asked for.
        minWidth(.maxContent)
        textAlign(.start)
      }
      selector("& .table-tbody td", "& .table-tfoot td") {
        backgroundColor(.inherit)
        padding(spacing8, spacing12)
        height(px(44))
        minHeight(px(44))
        maxHeight(px(44))
        boxSizing(.borderBox)
        verticalAlign(.middle)
        overflow(.hidden)
        textOverflow(.ellipsis)
        whiteSpace(.nowrap)
        minWidth(0)
        textAlign(.start)
      }
      selector("& [data-align='center']") { textAlign(.center) }
      selector("& [data-align='end']", "& [data-align='number']") { textAlign(.end) }
      selector("& .table-table-borders-vertical th", "& .table-table-borders-vertical td") {
        borderInlineStart(borderWidthBase, .solid, borderColorBase)
      }
      descendant(".table-selection-container") {
        display(.flex)
        alignItems(.center)
        justifyContent(.center)
      }
      selector(".table-selection-container input", ".table-selection-container label", ".table-selection-container button") { cursor(.pointer).important() }
      descendant(".table-resizer") {
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
        backgroundColor(borderColorBase)
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
      descendant(".table-footer") {
        padding(spacing12)
        marginBlockStart(spacing8)
      }
      descendant(".table-sort-label") {
        overflow(.hidden)
        textOverflow(.ellipsis)
        whiteSpace(.nowrap)
        minWidth(px(0))
        flexGrow(1)
        flexShrink(1)
      }
      descendant(".table-sort-icon") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        width(sizeIconMedium)
        height(sizeIconMedium)
        fontSize(fontSizeXSmall12)
        flexShrink(0)
      }
      descendant(".table-sort-button") {
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
        minWidth(0)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        height(perc(100))
      }
      descendant(".table-header-label") {
        width(perc(100))
        overflow(.hidden)
        textOverflow(.ellipsis)
        whiteSpace(.nowrap)
        display(.block)
      }
      descendant(".table-selection-header") {
        width(px(44))
        minWidth(px(44))
        position(.sticky)
        top(0)
        zIndex(zIndexSticky).important()
        backgroundColor(backgroundColorBase).important()
        backgroundColor(backgroundColorNeutralSubtle).important()
      }
      descendant(".table-column-header") {
        position(.sticky)
        top(0)
        zIndex(zIndexSticky).important()
        backgroundColor(backgroundColorBase).important()
        backgroundColor(backgroundColorNeutralSubtle).important()
      }
      descendant(".table-th-spacer") {
        width(px(16))
        minWidth(px(16))
        position(.sticky)
        top(0)
        zIndex(zIndexSticky).important()
        backgroundColor(backgroundColorNeutralSubtle).important()
        borderRightWidth(px(0))
        padding(px(0))
      }
      selector("&.table-view-empty .table-tbody") {
        display(.flex)
        flexDirection(.column)
        flex(1)
      }
      // `margin: auto` rather than `flex: 1`: the message should sit in the
      // middle of the empty body, not stretch to fill it — stretched, the line
      // collapsed to nothing between the cell's own padding.
      selector("& .table-tbody td.table-empty-state > .table-empty-state-content") {
        display(.flex)
        flexDirection(.column)
        gap(spacing8)
        alignItems(.center)
        justifyContent(.center)
        textAlign(.center)
        width(perc(100))
        margin(.auto)
      }
      // The cell is the whole empty body, so it stretches to the row it sits in
      // and centres its line both ways. Without the stretch it kept its own 44px
      // and the message sat in the top-left corner of a tall white box.
      // Spelled through `.table-tbody td` so it outranks the cell rule that
      // sets `text-align: start` for every td: same specificity loses to
      // source order, and that rule comes later.
      selector("& .table-tbody td.table-empty-state") {
        padding(spacing24)
        textAlign(.center)
        color(colorSubtle)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        display(.flex)
        flexDirection(.column)
        alignItems(.center)
        justifyContent(.center)
        alignSelf(.stretch)
        width(perc(100))
        minHeight(px(120))
        flex(1)
      }
      descendant(".table-empty-row") {
        backgroundColor(backgroundColorBase).important()
        display(.flex)
        flexDirection(.column)
        flex(1)
      }
      descendant(".table-group-indent") {
        display(.inlineBlock)
        width(spacing24)
      }
      descendant(".table-cell-content") {
        width(perc(100))
        overflow(.hidden)
        textOverflow(.ellipsis)
        whiteSpace(.nowrap).important()
        display(.block)
      }
    }
    .style(prefix: false) {
      selector("body[data-table-resizing='true']") { cursor(.colResize) }
    }
  }

  private func buildRowClass(
    isSelected: Bool,
    isGroupHeader: Bool,
    isGroupChild: Bool,
    hasUrl: Bool = false,
    isLast: Bool,
    isEven: Bool,
    isInitiallyCollapsed: Bool,
    customClass: String = ""
  ) -> String {
    var classes = ["table-row"]
    if isSelected { classes.append("table-row-selected") }
    if isGroupHeader { classes.append("table-group-header") }
    if isGroupChild { classes.append("table-group-child table-row-animatable") }
    if hasUrl { classes.append("table-row-link") }
    if isLast { classes.append("table-row-last") }
    classes.append(isEven ? "table-row-even" : "table-row-odd")
    // A row that renders collapsed is also taken out of the layout. The class
    // above only fades and lifts it — it keeps its 44px — so a group rendered
    // shut still pushed the table open by a row per child. With 413 runs under
    // one specimen that was a thousand pixels of blank table. Expanding removes
    // this class first, then animates.
    if isInitiallyCollapsed { classes.append("table-row-collapsed table-row-hidden") }
    if !stringIsEmpty(customClass) { classes.append(customClass) }
    return stringJoin(classes, separator: " ")
  }

}

#if CLIENT
  import WebAPIs

  public class TableInstance: @unchecked Sendable {
    public static func updateZebraStriping(for table: DOM.Element) {
      let rows = table.querySelectorAll(".table-tbody tr")
      var visibleIndex = 0
      for row in rows {
        let isCollapsed = row.classList.contains("table-row-hidden")
        if isCollapsed {
          continue
        }
        if visibleIndex % 2 == 1 {
          _ = row.classList.add("table-row-even")
          _ = row.classList.remove("table-row-odd")
        } else {
          _ = row.classList.add("table-row-odd")
          _ = row.classList.remove("table-row-even")
        }
        visibleIndex += 1
      }
    }

    private var table: DOM.Element
    private var wrapper: DOM.Element
    private var tableTable: DOM.Element
    private var selectAllCheckbox: DOM.Element?
    private var rowInputs: [DOM.Element] = []
    private var sortButtons: [DOM.Element] = []
    private var groupHeaders: [DOM.Element] = []
    private var paginationPrevBtns: [DOM.Element] = []
    private var paginationNextBtns: [DOM.Element] = []
    private var paginationPageInputs: [DOM.Element] = []
    private var selectedRows: [String] = []
    private var collapsedGroups: [String] = []
    private var expandedSubrowGroups: [String] = []
    private var currentSort: (columnID: String, direction: String)?
    private var currentPage: Int = 1
    private var selectionMode: String = ""
    private var activeResizer: DOM.Element?
    private var startX: Double = 0
    private var startWidth: Double = 0
    private var targetTh: DOM.Element?
    private var moveListenerID: Int32 = -1
    private var upListenerID: Int32 = -1
    private struct WidthPair {
      let key: String
      var value: Double
    }

    private var startWidths: [WidthPair] = []
    private var dragFloor: Double = 150.0
    private var hasDragged: Bool = false

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

    private func setColumnWidth(for header: DOM.Element, width: Double) {
      guard let columnID = header.getAttribute(data("table-column-id")) else { return }
      guard let column = tableTable.querySelector("col[data-table-column-id='\(columnID)']") else { return }
      column.setAttribute("width", intToString(Int(ceil(width))))
    }

    private func setTableWidth(_ width: Double) {
      tableTable.setAttribute("width", intToString(Int(ceil(width))))
    }

    private func measureCellContent(_ cell: DOM.Element) -> Double {
      let tag = cell.tagName
      let tempCell = document.createElement(tag)
      tempCell.className = "\(cell.className) table-measure-cell"
      tempCell.innerHTML = cell.innerHTML

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
        divReplacement.className = "\(sortButton.className) table-measure-sort-button"
        divReplacement.innerHTML = sortButton.innerHTML

        if let parent = sortButton.parentElement {
          parent.insertBefore(divReplacement, sortButton)
          sortButton.remove()
        }
      }

      // Create a hidden measuring table hierarchy that matches the cascade classes
      // of the source table to inherit all typography and padding rules perfectly.
      let measureDiv = document.createElement(.div)
      measureDiv.className = "\(table.className) table-measure-root"

      let tempTable = document.createElement(.table)
      tempTable.className = "\(tableTable.className) table-measure-table"

      let tempSection: DOM.Element
      if stringEquals(tag, "th") || stringEquals(tag, "TH") {
        tempSection = document.createElement("thead")
        if let liveThead = table.querySelector("thead") {
          tempSection.className = liveThead.className
        }
      } else {
        tempSection = document.createElement(.tbody)
        if let liveTbody = table.querySelector(".table-tbody") {
          tempSection.className = liveTbody.className
        }
      }

      let tempTr = document.createElement(.tr)
      if let liveTr = cell.parentElement {
        tempTr.className = liveTr.className
      }

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

    public init(table: DOM.Element) {
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

      let sortColumn = table.getAttribute(data("sort-column")) ?? ""
      let sortOrder = table.getAttribute(data("sort-order")) ?? ""
      let hasInitialSort = !stringIsEmpty(sortColumn) && !stringIsEmpty(sortOrder)
      if hasInitialSort {
        currentSort = (sortColumn, sortOrder)
      }

      bindEvents()
      TableInstance.updateZebraStriping(for: table)

      let isServerPaginated = stringEquals(table.getAttribute(data("paginate-server")) ?? "false", "true")
      if !isServerPaginated {
        if hasInitialSort {
          // Apply initial sort by setting the opposite direction first so toggleSort
          // flips it back to the intended direction and reorders the DOM.
          let opposite = stringEquals(sortOrder, "asc") ? "desc" : "asc"
          currentSort = (sortColumn, opposite)
          toggleSort(columnID: sortColumn)
        }
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
          _ = chevron.addEventListener(.click) { [self] _ in
            self.toggleGroup(header)
          }
        }
      }

      // Nested sub-row group expand/collapse — ONLY chevron is clickable
      let subrowToggleRows = Array(table.querySelectorAll(".table-tbody tr:has(.lemma-history-toggle), .table-tbody tr:has(.table-subrow-toggle)"))
      for row in subrowToggleRows {
        if let toggle = row.querySelector(".lemma-history-toggle") ?? row.querySelector(".table-subrow-toggle") {
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
            guard let input = pageInput as? HTML.HTMLInputElement else { return }
            if let page = parseInt(input.value) {
              self.goToPage(page)
            }
          }
          _ = pageInput.addEventListener(.keydown) { [self] (event: Event) in
            if stringEquals(event.key, "ArrowUp") {
              event.preventDefault()
              guard let input = pageInput as? HTML.HTMLInputElement else { return }
              let cur = parseInt(input.value) ?? 1
              let maxVal = input.getAttribute("max").flatMap { parseInt($0) } ?? 999999
              let next = min(cur + 1, maxVal)
              input.value = intToString(next)
              return
            }
            if stringEquals(event.key, "ArrowDown") {
              event.preventDefault()
              guard let input = pageInput as? HTML.HTMLInputElement else { return }
              let cur = parseInt(input.value) ?? 1
              let minVal = input.getAttribute("min").flatMap { parseInt($0) } ?? 1
              let next = max(cur - 1, minVal)
              input.value = intToString(next)
              return
            }
            if stringEquals(event.key, "Enter") {
              event.preventDefault()
              guard let input = pageInput as? HTML.HTMLInputElement else { return }
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

    private func initResize(_ event: Event, resizer: DOM.Element) {
      let mouseEvent = MouseEvent(event)
      activeResizer = resizer
      targetTh = resizer.parentElement
      startX = mouseEvent.clientX
      hasDragged = false
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
      let headerCells = parentTr?.querySelectorAll("th") ?? Array<DOM.Element>()
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
      document.body.setAttribute(data("table-resizing"), true)
      
      moveListenerID = window.addEventListener(.mousemove, onResize)
      upListenerID = window.addEventListener(.mouseup, stopResize)
      
      // Prevent text selection during drag
      mouseEvent.preventDefault()
    }

    private func onResize(_ event: Event) {
      guard let th = targetTh else { return }
      let mouseEvent = MouseEvent(event)
      let delta = mouseEvent.clientX - startX
      hasDragged = true
      let newWidth = max(dragFloor, startWidth + delta)
      
      setColumnWidth(for: th, width: newWidth)
      
      // Update tableTable width to sum of all columns, pinning each column explicitly
      // to prevent table-layout: fixed from redistributing widths during resize.
      let headers = Array(self.table.querySelectorAll("thead th")).filter { !$0.classList.contains("table-th-spacer") }
      var total: Double = 0
      let activeId = th.getAttribute(.id) ?? ""
      for header in headers {
        let headerId = header.getAttribute(.id) ?? ""
        var w: Double = 0
        if !stringIsEmpty(headerId) && stringEquals(headerId, activeId) {
          w = newWidth
          setColumnWidth(for: header, width: w)
          total += w
        } else {
          w = getStartWidth(for: headerId) ?? Double(header.getBoundingClientRect()?.width ?? 100)
          setColumnWidth(for: header, width: w)
          total += w
        }
      }

      setTableWidth(total)
    }

    private func snapResize(_ event: Event, resizer: DOM.Element) {
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
      
      // Snap to the measured content width, rounded up to avoid fractional
      // subpixel truncation in Safari. The colgroup owns the resulting width.
      let finalWidth = ceil(maxWidth)
      
      let headers = Array(self.table.querySelectorAll("thead th")).filter { !$0.classList.contains("table-th-spacer") }
      
      var total: Double = 0
      let activeId = th.getAttribute(.id) ?? ""
      for header in headers {
        let headerId = header.getAttribute(.id) ?? ""
        if !stringIsEmpty(headerId) && stringEquals(headerId, activeId) {
          setColumnWidth(for: header, width: min(finalWidth, 2000.0))
          total += finalWidth
        } else {
          let w = getStartWidth(for: headerId) ?? Double(header.getBoundingClientRect()?.width ?? 150.0)
          setColumnWidth(for: header, width: w)
          total += w
        }
      }
      
      setTableWidth(total)
    }

    private func stopResize(_ event: Event) {
      activeResizer?.classList.remove("resizing")
      document.body.setAttribute(data("table-resizing"), false)
      
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

    private func toggleGroup(_ header: DOM.Element) {
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
          child.classList.remove("table-row-hidden")
          child.classList.add("table-row-collapsed")
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
              subRow.classList.add("table-row-hidden")
            }
            
            // Reset any rotated chevrons inside the child row
            let childChevrons = child.querySelectorAll("[data-expanded='true']")
            for chevron in childChevrons {
              chevron.setAttribute(data("expanded"), "false")
            }
          }
        }
        
        // After transition completes, hide from layout
        window.setTimeout(250) { [self] in
          for child in childRows {
            if child.classList.contains("table-row-collapsed") {
              child.classList.add("table-row-hidden")
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
          rightDownChevron.setAttribute(data("expanded"), "true")
        } else {
          rightDownChevron.setAttribute(data("expanded"), "false")
        }
      }

      // Dispatch group toggle event
      let event = CustomEvent(
        type: "table-group-toggle",
        detail: "\(groupID):\(isCollapsed ? "expanded" : "collapsed")")
      self.table.dispatchEvent(event)
    }

    private func toggleSubrowGroup(_ parentRow: DOM.Element, parentID: String) {
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
              subRow.classList.add("table-row-hidden")
            }
          }
          TableInstance.updateZebraStriping(for: self.table)
        }
      } else {
        // Expanding → show first (starting from collapsed opacity/transform), then transition in
        for subRow in subRows {
          subRow.classList.remove("table-row-hidden")
          subRow.classList.add("table-row-collapsed")
          _ = subRow.getBoundingClientRect() // Force layout reflow
        }
        TableInstance.updateZebraStriping(for: self.table)
        
        // Ensure first radio is checked on expand
        var radioToCheck: DOM.Element? = nil
        for subRow in subRows {
          if let radio = subRow.querySelector("input[type='radio']") {
            radioToCheck = radio
            break
          }
        }
        if let radio = radioToCheck as? HTML.HTMLInputElement {
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
          svg.setAttribute(data("expanded"), "false")
        } else {
          svg.setAttribute(data("expanded"), "true")
        }
      }
    }

    private func toggleSelectAll() {
      guard let selectAll = selectAllCheckbox else { return }
      let isChecked = (selectAll as? HTML.HTMLInputElement)?.checked ?? false

      for input in rowInputs {
        (input as? HTML.HTMLInputElement)?.checked = isChecked
      }

      updateRowSelection()
    }

    private func updateRowSelection() {
      selectedRows = []

      for input in rowInputs {
        if (input as? HTML.HTMLInputElement)?.checked == true {
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
            (selectAll as? HTML.HTMLInputElement)?.checked = false
            selectAll.indeterminate = false
          } else if selectedRows.count == rowInputs.count {
            (selectAll as? HTML.HTMLInputElement)?.checked = true
            selectAll.indeterminate = false
          } else {
            (selectAll as? HTML.HTMLInputElement)?.checked = false
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
      let isServerPaginated = stringEquals(table.getAttribute(data("paginate-server")) ?? "false", "true")
      let baseUrl = table.getAttribute(data("pagination-base-url")) ?? ""

      if isServerPaginated && !stringIsEmpty(baseUrl) {
        var direction = "asc"
        if let current = currentSort, stringEquals(current.columnID, columnID) {
          direction = stringEquals(current.direction, "asc") ? "desc" : "asc"
        }
        let base = window.location.pathname
        let url = "\(base)?sort=\(columnID)&order=\(direction)&page=1"
        window.location.href = url
        return
      }

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

      // Get tbody and its rows.
      guard let tbodyEl = self.table.querySelector("tbody") else { return }
      let allRows = Array(tbodyEl.querySelectorAll("tr"))
      let sortableRows = allRows
      guard sortableRows.count > 1 else { return }

      // Build row groups hierarchically:
      // - A top-level batch group (headerRow: DOM.Element, lemmaGroups: [(parentRow: DOM.Element, historyRows: [DOM.Element])])
      var batchGroups: [(headerRow: DOM.Element, lemmaGroups: [(parentRow: DOM.Element, historyRows: [DOM.Element])])] = []
      
      for row in sortableRows {
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
          icon.setAttribute(data("active"), true)
          if let chevron = AnimatedUpDownChevronFactory.from(element: icon) {
            chevron.morph(toExpanded: !isAscending)
          }
        } else {
          // Hide inactive columns and reset to collapsed (down-pointing)
          icon.setAttribute(data("active"), false)
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
      let allDataRows = Array(rows).filter {
        !$0.classList.contains("table-empty-row")
        && !$0.classList.contains("table-sub-row")
        && !$0.classList.contains("lemma-history-sub-row")
      }
      // Top-level rows only (exclude group children) for pagination and display count
      let topLevelRows = allDataRows.filter {
        !$0.classList.contains("table-group-child")
        && !$0.classList.contains("batch-group-child")
      }
      // Use server-provided total-items when available (authoritative; avoids counting subrows)
      let serverTotal = parseInt(table.getAttribute(data("total-items")) ?? "")
      let displayTotal = serverTotal ?? topLevelRows.count

      let maxPage = displayTotal == 0 ? 1 : (displayTotal + pageSize - 1) / pageSize

      guard page > 0 && page <= maxPage else { return }

      currentPage = page

      // Sync all pagination inputs
      for pageInput in paginationPageInputs {
        if let input = pageInput as? HTML.HTMLInputElement {
          input.value = intToString(page)
        }
      }

      if isPaginated {
        let startIdx = (page - 1) * pageSize
        let endIdx = min(startIdx + pageSize, topLevelRows.count)

        // A page is a page of parent rows. Children come with their parent —
        // shown when the parent is on this page and its group is open, hidden
        // otherwise — rather than being counted into the page themselves.
        var visibleGroupIDs: [String] = []
        var topLevelIndex = 0
        for row in allDataRows {
          let isGroupChild =
            row.classList.contains("table-group-child")
            || row.classList.contains("batch-group-child")
          if isGroupChild { continue }
          if topLevelIndex >= startIdx && topLevelIndex < endIdx {
            row.classList.remove("table-row-hidden")
            let groupID = row.getAttribute(data("group-id")) ?? ""
            if !stringIsEmpty(groupID) { visibleGroupIDs.append(groupID) }
          } else {
            row.classList.add("table-row-hidden")
          }
          topLevelIndex += 1
        }
        for row in allDataRows {
          let isGroupChild =
            row.classList.contains("table-group-child")
            || row.classList.contains("batch-group-child")
          guard isGroupChild else { continue }
          let groupID = row.getAttribute(data("group-id")) ?? ""
          let parentOnPage = visibleGroupIDs.contains(where: { stringEquals($0, groupID) })
          let isCollapsed = collapsedGroups.contains(where: { stringEquals($0, groupID) })
          if parentOnPage && !isCollapsed {
            row.classList.remove("table-row-hidden")
          } else {
            row.classList.add("table-row-hidden")
          }
        }

        // Update pagination info text: Showing results X–Y of Z
        let infoEls = table.querySelectorAll(".pagination-info")
        let showingStart = displayTotal == 0 ? 0 : startIdx + 1
        let infoText = "Showing results \(showingStart)–\(endIdx) of \(displayTotal)"
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
      @HTMLBuilder header: () -> [DOM.Node] = { [] },
      @HTMLBuilder thead: () -> [DOM.Node] = { [] },
      @HTMLBuilder tbody: () -> [DOM.Node] = { [] },
      @HTMLBuilder tfoot: () -> [DOM.Node] = { [] },
      @HTMLBuilder footer: () -> [DOM.Node] = { [] },
      @HTMLBuilder emptyState: () -> [DOM.Node] = { [] }
    ) -> DOM.Element {
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

      wrapper.innerHTML = view.render()

      return wrapper.firstElementChild ?? wrapper
    }
  }

  public class TableHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: TableHydration?
    private var instances: [TableInstance] = []

    public init() {
      hydrateAllTables()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".table-view") != nil else { return }
      instance = TableHydration()
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
