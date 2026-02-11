#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A structural component used to arrange data in rows and columns.
public struct TableView: HTMLProtocol {
	let captionContent: String
	let hideCaption: Bool
	let columns: [Column]
	let data: [Row]
	let useRowHeaders: Bool
	let showVerticalBorders: Bool
	let selectionMode: SelectionMode?
	let selectedRows: [String]
	let sort: Sort?
	let pending: Bool
	let paginate: Bool
	let paginationPosition: PaginationPosition
	let paginationSizeDefault: Int
	let headerContent: [HTMLProtocol]
	let theadContent: [HTMLProtocol]
	let tbodyContent: [HTMLProtocol]
	let tfootContent: [HTMLProtocol]
	let footerContent: [HTMLProtocol]
	let emptyStateContent: [HTMLProtocol]
	let theadStyle: (@Sendable () -> [any CSSProtocol])?
	let thStyle: (@Sendable (Column.Alignment) -> [any CSSProtocol])?
	let `class`: String

	public struct Column: Sendable {
		let id: String
		let label: String
		let sortable: Bool
		let align: Alignment
		let width: String?

		public enum Alignment: Sendable {
			case start
			case center
			case end
			case number

			var value: String {
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
			sortable: Bool = false,
			align: Alignment = .start,
			width: String? = nil
		) {
			self.id = id
			self.label = label
			self.sortable = sortable
			self.align = align
			self.width = width
		}
	}

	public struct Row: Sendable {
		let id: String?
		let cells: [String: String]
		let groupId: String?  // Groups rows together - first row with groupId becomes collapsible header
		let isGroupHeader: Bool  // True if this row is a group header (rendered with expand/collapse)

		public init(
			id: String? = nil,
			cells: [String: String],
			groupId: String? = nil,
			isGroupHeader: Bool = false
		) {
			self.id = id
			self.cells = cells
			self.groupId = groupId
			self.isGroupHeader = isGroupHeader
		}
	}

	public struct Sort: Sendable {
		let columnId: String
		let direction: Direction

		public enum Direction: Sendable {
			case ascending
			case descending
			
			var value: String {
				switch self {
				case .ascending: return "asc"
				case .descending: return "desc"
				}
			}
		}

		public init(columnId: String, direction: Direction) {
			self.columnId = columnId
			self.direction = direction
		}
	}

	public enum PaginationPosition: Sendable {
		case top
		case bottom
		case both

		var value: String {
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

		var value: String {
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
		theadStyle: (@Sendable () -> [any CSSProtocol])? = nil,
		thStyle: (@Sendable (Column.Alignment) -> [any CSSProtocol])? = nil,
		class: String = "",
		@HTMLBuilder header: () -> [HTMLProtocol] = { [] },
		@HTMLBuilder thead: () -> [HTMLProtocol] = { [] },
		@HTMLBuilder tbody: () -> [HTMLProtocol] = { [] },
		@HTMLBuilder tfoot: () -> [HTMLProtocol] = { [] },
		@HTMLBuilder footer: () -> [HTMLProtocol] = { [] },
		@HTMLBuilder emptyState: () -> [HTMLProtocol] = { [] }
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
		self.`class` = `class`
		self.headerContent = header()
		self.theadContent = thead()
		self.tbodyContent = tbody()
		self.tfootContent = tfoot()
		self.footerContent = footer()
		self.emptyStateContent = emptyState()
	}

	public func render(indent: Int = 0) -> String {
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
												hideLabel: true
											) {
												"Select all"
											}
										}
										// For single selection mode, just an empty header cell
									}
									.scope(.col)
									.style {
										if let ts = thStyle {
											ts(.start)
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

												if let currentSort = sort, currentSort.columnId == column.id {
													span {
														currentSort.direction == .ascending ? "▲" : "▼"
													}
													.class("table-sort-icon")
													.ariaHidden(true)
													.style {
														tableSortIconCSS()
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
										if let ts = thStyle {
											ts(column.align)
										} else {
											tableThCSS(column.align)
										}
									}
								}
							}
						}
						.class("table-thead")
						.style {
							if let ths = theadStyle {
								ths()
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
							} else {
								for (rowIndex, row) in data.enumerated() {
									let rowId = row.id ?? String(rowIndex)
									let isSelected = selectedRows.contains(rowId)
									let isGroupChild = row.groupId != nil && !row.isGroupHeader

									tr {
										// Row selection (checkbox for multiple, radio for single)
										if let mode = selectionMode {
											td {
												if mode == .multiple {
													CheckboxView(
														id: "row-\(rowId)",
														name: "row-selection",
														value: rowId,
														checked: isSelected,
														hideLabel: true
													) {
														"Select row"
													}
												} else {
													RadioView(
														id: "row-\(rowId)",
														name: "row-selection",
														value: rowId,
														checked: isSelected,
														hideLabel: true
													) {
														"Select row"
													}
												}
											}
											.style {
												tableTdCSS(.start)
											}
										}

										// Row cells
										for (cellIndex, column) in columns.enumerated() {
											let cellContent = row.cells[column.id] ?? ""
											let isFirstCell = cellIndex == 0

											if useRowHeaders && isFirstCell {
												th {
													// Group header gets expand/collapse toggle
													if row.isGroupHeader {
														span {
															CollapseIconView()
														}
														.class("group-toggle group-expanded")
														.ariaHidden(true)
														.style {
																display(.inlineBlock)
																marginInlineEnd(spacing8)
																cursor(cursorBase)
															}
														span {
															ExpandIconView()
														}
														.class("group-toggle group-collapsed")
														.ariaHidden(true)
														.style {
															display(.none)
															marginInlineEnd(spacing8)
															cursor(cursorBase)
														}
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
													// Group header first cell gets expand/collapse toggle
													if row.isGroupHeader && isFirstCell {
														span {
															CollapseIconView()
														}
														.class("group-toggle group-expanded")
														.ariaHidden(true)
														.style {
															display(.inlineBlock)
															marginInlineEnd(spacing8)
															cursor(cursorBase)
														}
														span {
															ExpandIconView()
														}
														.class("group-toggle group-collapsed")
														.ariaHidden(true)
														.style {
															display(.none)
															marginInlineEnd(spacing8)
															cursor(cursorBase)
														}
													}
													// Child rows get indentation on first cell
													if isGroupChild && isFirstCell {
														span { "" }
															.style {
																display(.inlineBlock)
																width(spacing24)
															}
													}
													cellContent
												}
												.style {
													tableTdCSS(column.align)
													if row.isGroupHeader {
														fontWeight(fontWeightBold)
														backgroundColor(backgroundColorNeutralSubtle)
													}
												}
											}
										}
									}
									.data("row-id", rowId)
									.data("group-id", row.groupId ?? "")
									.data("is-group-header", row.isGroupHeader ? "true" : "")
									.class(buildRowClass(isSelected: isSelected, isGroupHeader: row.isGroupHeader, isGroupChild: isGroupChild))
								}
							}
						}
						.class("table-tbody")
						.style {
							tableTbodyCSS()
						}
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
				.class(showVerticalBorders ? "table-table table-table-borders-vertical" : "table-table")
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
		.class(`class`.isEmpty ? "table-view" : "table-view \(`class`)")
		.data("selection-mode", selectionMode?.value ?? "")
		.data("paginate", paginate ? true : false)
		.style {
			tableViewCSS()
		}
		.render(indent: indent)
	}

	private func buildRowClass(isSelected: Bool, isGroupHeader: Bool, isGroupChild: Bool) -> String {
		var classes = ["table-row"]
		if isSelected { classes.append("table-row-selected") }
		if isGroupHeader { classes.append("table-group-header") }
		if isGroupChild { classes.append("table-group-child") }
		return classes.joined(separator: " ")
	}

    @CSSBuilder
	private func tableViewCSS() -> [CSSProtocol] {
		width(perc(100))
	}

	@CSSBuilder
	private func tableHeaderCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		justifyContent(.spaceBetween)
		gap(spacing12)
		padding(spacing12)
		marginBlockEnd(spacing8)
	}

	@CSSBuilder
	private func tableHeaderTitleCSS() -> [CSSProtocol] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeLarge18)
		fontWeight(fontWeightBold)
		lineHeight(lineHeightMedium26)
		color(colorBase)
		margin(0)
	}

	@CSSBuilder
	private func tableWrapperCSS() -> [CSSProtocol] {
		overflowX(.auto)
		border(borderWidthBase, .solid, borderColorSubtle)
		borderRadius(borderRadiusBase)
	}

	@CSSBuilder
	private func tableTableCSS(_ showVerticalBorders: Bool) -> [CSSProtocol] {
		width(perc(100))
		borderCollapse(.collapse)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightMedium26)
		color(colorBase)

		if showVerticalBorders {
			selector(" td, th") {
				borderInlineEnd(borderWidthBase, .solid, borderColorSubtle)
			}

			selector(" td:last-child, th:last-child") {
				borderInlineEnd(.none)
			}
		}
	}

	@CSSBuilder
	private func tableCaptionCSS(_ hideCaption: Bool) -> [CSSProtocol] {
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
	private func tableTheadCSS() -> [CSSProtocol] {
		backgroundColor(backgroundColorNeutralSubtle)
		borderBlockEnd(borderWidthBase, .solid, borderColorSubtle)
	}

	@CSSBuilder
	private func tableThCSS(_ align: Column.Alignment) -> [CSSProtocol] {
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
	private func tableSortButtonCSS() -> [CSSProtocol] {
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
		cursor(cursorBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

		pseudoClass(.hover) {
			color(colorBlue).important()
		}

		pseudoClass(.active) {
			color(colorBlueActive).important()
		}
	}

	@CSSBuilder
	private func tableSortIconCSS() -> [CSSProtocol] {
		display(.inlineFlex)
		width(sizeIconSmall)
		height(sizeIconSmall)
		fontSize(fontSizeXSmall12)
	}

	@CSSBuilder
	private func tableTbodyCSS() -> [CSSProtocol] {
		selector("tr") {
			borderBlockEnd(borderWidthBase, .solid, borderColorSubtle)
		}

		selector("tr:last-child") {
			borderBlockEnd(.none)
		}

		selector("tr:hover") {
			backgroundColor(backgroundColorInteractiveSubtleHover).important()
		}
	}

	@CSSBuilder
	private func tableTdCSS(_ align: Column.Alignment) -> [CSSProtocol] {
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
	private func tableTfootCSS() -> [CSSProtocol] {
		backgroundColor(backgroundColorNeutralSubtle)
		borderBlockStart(borderWidthBase, .solid, borderColorSubtle)
		fontWeight(fontWeightBold)
	}

	@CSSBuilder
	private func tableEmptyStateCSS() -> [CSSProtocol] {
		padding(spacing48)
		textAlign(.center)
		color(colorSubtle)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightMedium26)
	}

	@CSSBuilder
	private func tableFooterCSS() -> [CSSProtocol] {
		padding(spacing12)
		marginBlockStart(spacing8)
	}

	@CSSBuilder
	private func tablePaginationCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		justifyContent(.spaceBetween)
		gap(spacing12)
		padding(spacing12)
		borderBlockStart(borderWidthBase, .solid, borderColorSubtle)
		flexWrap(.wrap)
	}

	@CSSBuilder
	private func paginationInfoCSS() -> [CSSProtocol] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
	}

	@CSSBuilder
	private func paginationControlsCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		gap(spacing8)
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

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
    private var currentSort: (columnId: String, direction: String)?
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

        // Group header expand/collapse
        for header in groupHeaders {
            _ = header.addEventListener(.click) { [self] event in
                // Only toggle if clicking on the toggle icon area
                if let target = event.target {
                    let classList = target.className
                    if stringContains(classList, "group-toggle") || stringContains(classList, "icon") {
                        self.toggleGroup(header)
                    }
                }
            }
        }

        // Sort buttons
        for button in sortButtons {
            _ = button.addEventListener(.click) { [self] _ in
                guard let columnId = button.getAttribute("data-column-id") else { return }
                self.toggleSort(columnId: columnId)
            }
        }

        // Pagination buttons
        if let firstBtn = paginationFirstBtn {
            _ = firstBtn.addEventListener(.click) { [self] _ in
                self.goToPage(1)
            }
        }

        if let prevBtn = paginationPrevBtn {
            _ = prevBtn.addEventListener(.click) { [self] _ in
                self.goToPage(self.currentPage - 1)
            }
        }

        if let nextBtn = paginationNextBtn {
            _ = nextBtn.addEventListener(.click) { [self] _ in
                self.goToPage(self.currentPage + 1)
            }
        }

        if let lastBtn = paginationLastBtn {
            _ = lastBtn.addEventListener(.click) { [self] _ in
                self.goToPage(10)
            }
        }
    }

    private func toggleGroup(_ header: Element) {
        guard let groupId = header.getAttribute("data-group-id"), !groupId.isEmpty else { return }

        // Check if currently collapsed
        let isCollapsed = collapsedGroups.contains(where: { stringEquals($0, groupId) })

        if isCollapsed {
            // Expand: remove from collapsed list
            collapsedGroups = collapsedGroups.filter { !stringEquals($0, groupId) }
        } else {
            // Collapse: add to collapsed list
            collapsedGroups.append(groupId)
        }

        // Update visibility of child rows
        let childRows = table.querySelectorAll(".table-group-child[data-group-id='\(groupId)']")
        for child in childRows {
            if isCollapsed {
                child.style.display(.tableRow)
            } else {
                child.style.display(.none)
            }
        }

        // Update toggle icon visibility
        let expandedIcon = header.querySelector(".group-expanded")
        let collapsedIcon = header.querySelector(".group-collapsed")

        if isCollapsed {
            // Now expanded
            expandedIcon?.style.display(.inlineBlock)
            collapsedIcon?.style.display(.none)
        } else {
            // Now collapsed
            expandedIcon?.style.display(.none)
            collapsedIcon?.style.display(.inlineBlock)
        }

        // Dispatch group toggle event
        let event = CustomEvent(type: "table-group-toggle", detail: "\(groupId):\(isCollapsed ? "expanded" : "collapsed")")
        table.dispatchEvent(event)
    }

    private func toggleSelectAll() {
        guard let selectAll = selectAllCheckbox else { return }
        let isChecked = selectAll.checked

        for input in rowInputs {
            input.checked = isChecked
        }

        updateRowSelection()
    }

    private func updateRowSelection() {
        selectedRows = []

        for input in rowInputs {
            if input.checked {
                if let idStr = input.getAttribute(.id) {
                    if stringContains(idStr, "row-") {
                        // Manual substring to avoid String(decoding:) trigger via stringReplace, but use safe decoding
                        var rowIdBytes: [UInt8] = []
                        let bytes = Array(idStr.utf8)
                        // "row-" is 4 bytes
                        if bytes.count > 4 {
                            for i in 4..<bytes.count {
                                rowIdBytes.append(bytes[i])
                            }
                        }
                        let rowId = String(decoding: rowIdBytes, as: UTF8.self)
                        selectedRows.append(rowId)
                    }
                }
            }
        }

        // Update select all checkbox state (only for multiple selection mode)
        if stringEquals(selectionMode, "multiple") {
            if let selectAll = selectAllCheckbox {
                if selectedRows.isEmpty {
                    selectAll.checked = false
                    selectAll.indeterminate = false
                } else if selectedRows.count == rowInputs.count {
                    selectAll.checked = true
                    selectAll.indeterminate = false
                } else {
                    selectAll.checked = false
                    selectAll.indeterminate = true
                }
            }
        }

        // Dispatch selection change event
        var joinedBytes: [UInt8] = []
        for (index, row) in selectedRows.enumerated() {
            if index > 0 {
                joinedBytes.append(44) // comma
            }
            joinedBytes.append(contentsOf: row.utf8)
        }
        let joinedRows = String(decoding: joinedBytes, as: UTF8.self)
        let event = CustomEvent(type: "table-selection-change", detail: joinedRows)
        table.dispatchEvent(event)
    }

    private func toggleSort(columnId: String) {
        // Toggle sort direction
        if let current = currentSort, stringEquals(current.columnId, columnId) {
            let newDirection = stringEquals(current.direction, "asc") ? "desc" : "asc"
            currentSort = (columnId, newDirection)
        } else {
            currentSort = (columnId, "asc")
        }

        // Dispatch sort event
        let sortData = "\(columnId):\(currentSort?.direction ?? "asc")"
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
