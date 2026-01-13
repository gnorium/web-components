#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Table component following Wikimedia Codex design system specification
/// A structural component used to arrange data in rows and columns.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/table.html
public struct TableView: HTML {
	let captionContent: String
	let hideCaption: Bool
	let columns: [Column]
	let data: [Row]
	let useRowHeaders: Bool
	let showVerticalBorders: Bool
	let useRowSelection: Bool
	let selectedRows: [String]
	let sort: Sort?
	let pending: Bool
	let paginate: Bool
	let paginationPosition: PaginationPosition
	let paginationSizeDefault: Int
	let headerContent: [HTML]
	let theadContent: [HTML]
	let tbodyContent: [HTML]
	let tfootContent: [HTML]
	let footerContent: [HTML]
	let emptyStateContent: [HTML]
	let theadStyle: (@Sendable () -> [any CSS])?
	let thStyle: (@Sendable (Column.Alignment) -> [any CSS])?
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

		public init(id: String? = nil, cells: [String: String]) {
			self.id = id
			self.cells = cells
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

	public init(
		captionContent: String,
		hideCaption: Bool = false,
		columns: [Column] = [],
		data: [Row] = [],
		useRowHeaders: Bool = false,
		showVerticalBorders: Bool = false,
		useRowSelection: Bool = false,
		selectedRows: [String] = [],
		sort: Sort? = nil,
		pending: Bool = false,
		paginate: Bool = false,
		paginationPosition: PaginationPosition = .bottom,
		paginationSizeDefault: Int = 10,
		theadStyle: (@Sendable () -> [any CSS])? = nil,
		thStyle: (@Sendable (Column.Alignment) -> [any CSS])? = nil,
		class: String = "",
		@HTMLBuilder header: () -> [HTML] = { [] },
		@HTMLBuilder thead: () -> [HTML] = { [] },
		@HTMLBuilder tbody: () -> [HTML] = { [] },
		@HTMLBuilder tfoot: () -> [HTML] = { [] },
		@HTMLBuilder footer: () -> [HTML] = { [] },
		@HTMLBuilder emptyState: () -> [HTML] = { [] }
	) {
		self.captionContent = captionContent
		self.hideCaption = hideCaption
		self.columns = columns
		self.data = data
		self.useRowHeaders = useRowHeaders
		self.showVerticalBorders = showVerticalBorders
		self.useRowSelection = useRowSelection
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

	@CSSBuilder
	private func tableViewCSS() -> [CSS] {
		width(perc(100))
	}

	@CSSBuilder
	private func tableHeaderCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		justifyContent(.spaceBetween)
		gap(spacing12)
		padding(spacing12)
		marginBottom(spacing8)
	}

	@CSSBuilder
	private func tableHeaderTitleCSS() -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeLarge18)
		fontWeight(fontWeightBold)
		lineHeight(lineHeightMedium26)
		color(colorBase)
		margin(0)
	}

	@CSSBuilder
	private func tableWrapperCSS() -> [CSS] {
		overflowX(.auto)
		border(borderWidthBase, .solid, borderColorSubtle)
		borderRadius(borderRadiusBase)
	}

	@CSSBuilder
	private func tableTableCSS(_ showVerticalBorders: Bool) -> [CSS] {
		width(perc(100))
		borderCollapse(.collapse)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightMedium26)
		color(colorBase)

		if showVerticalBorders {
			selector(" td, th") {
				borderRight(borderWidthBase, .solid, borderColorSubtle)
			}

			selector(" td:last-child, th:last-child") {
				borderRight(.none)
			}
		}
	}

	@CSSBuilder
	private func tableCaptionCSS(_ hideCaption: Bool) -> [CSS] {
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
	private func tableTheadCSS() -> [CSS] {
		backgroundColor(backgroundColorNeutralSubtle)
		borderBottom(borderWidthBase, .solid, borderColorSubtle)
	}

	@CSSBuilder
	private func tableThCSS(_ align: Column.Alignment) -> [CSS] {
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
			textAlign(.right)
		}
	}

	@CSSBuilder
	private func tableSortButtonCSS() -> [CSS] {
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
			color(colorProgressive).important()
		}

		pseudoClass(.active) {
			color(colorProgressiveActive).important()
		}
	}

	@CSSBuilder
	private func tableSortIconCSS() -> [CSS] {
		display(.inlineFlex)
		width(sizeIconSmall)
		height(sizeIconSmall)
		fontSize(fontSizeXSmall12)
	}

	@CSSBuilder
	private func tableTbodyCSS() -> [CSS] {
		selector("tr") {
			borderBottom(borderWidthBase, .solid, borderColorSubtle)
		}

		selector("tr:last-child") {
			borderBottom(.none)
		}

		selector("tr:hover") {
			backgroundColor(backgroundColorInteractiveSubtleHover).important()
		}
	}

	@CSSBuilder
	private func tableTdCSS(_ align: Column.Alignment) -> [CSS] {
		padding(spacing12)

		switch align {
		case .start:
			textAlign(.start)
		case .center:
			textAlign(.center)
		case .end:
			textAlign(.end)
		case .number:
			textAlign(.right)
		}
	}

	@CSSBuilder
	private func tableTfootCSS() -> [CSS] {
		backgroundColor(backgroundColorNeutralSubtle)
		borderTop(borderWidthBase, .solid, borderColorSubtle)
		fontWeight(fontWeightBold)
	}

	@CSSBuilder
	private func tableEmptyStateCSS() -> [CSS] {
		padding(spacing48)
		textAlign(.center)
		color(colorSubtle)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightMedium26)
	}

	@CSSBuilder
	private func tableFooterCSS() -> [CSS] {
		padding(spacing12)
		marginTop(spacing8)
	}

	@CSSBuilder
	private func tablePaginationCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		justifyContent(.spaceBetween)
		gap(spacing12)
		padding(spacing12)
		borderTop(borderWidthBase, .solid, borderColorSubtle)
		flexWrap(.wrap)
	}

	@CSSBuilder
	private func paginationInfoCSS() -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
	}

	@CSSBuilder
	private func paginationControlsCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		gap(spacing8)
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
							ButtonView(label: "First", action: .default, weight: .quiet)
						}
						.class("pagination-first")

						div {
							ButtonView(label: "Previous", action: .default, weight: .quiet)
						}
						.class("pagination-previous")

						div {
							ButtonView(label: "Next", action: .default, weight: .quiet)
						}
						.class("pagination-next")

						div {
							ButtonView(label: "Last", action: .default, weight: .quiet)
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
								// Select all checkbox
								if useRowSelection {
									th {
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
									.colspan(columns.count + (useRowSelection ? 1 : 0))
									.class("table-empty-state")
									.style {
										tableEmptyStateCSS()
									}
								}
							} else {
								for (rowIndex, row) in data.enumerated() {
									tr {
										// Row selection checkbox
										if useRowSelection {
											td {
												CheckboxView(
													id: "row-\(row.id ?? String(rowIndex))",
													name: "row-selection",
													value: row.id ?? String(rowIndex),
													checked: selectedRows.contains(row.id ?? String(rowIndex)),
													hideLabel: true
												) {
													"Select row"
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
													cellContent
												}
												.scope(.row)
												.style {
													tableThCSS(column.align)
												}
											} else {
												td {
													cellContent
												}
												.style {
													tableTdCSS(column.align)
												}
											}
										}
									}
									.data("row-id", row.id ?? String(rowIndex))
									.class(selectedRows.contains(row.id ?? String(rowIndex)) ? "table-row table-row-selected" : "table-row")
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
							ButtonView(label: "First", action: .default, weight: .quiet)
						}
						.class("pagination-first")

						div {
							ButtonView(label: "Previous", action: .default, weight: .quiet)
						}
						.class("pagination-previous")

						div {
							ButtonView(label: "Next", action: .default, weight: .quiet)
						}
						.class("pagination-next")

						div {
							ButtonView(label: "Last", action: .default, weight: .quiet)
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
		.data("use-row-selection", useRowSelection ? true : false)
		.data("paginate", paginate ? true : false)
		.style {
			tableViewCSS()
		}
		.render(indent: indent)
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
		private var rowCheckboxes: [Element] = []
		private var sortButtons: [Element] = []
		private var paginationFirstBtn: Element?
		private var paginationPrevBtn: Element?
		private var paginationNextBtn: Element?
		private var paginationLastBtn: Element?
		private var selectedRows: [String] = []
		private var currentSort: (columnId: String, direction: String)?
		private var currentPage: Int = 1

		init(table: Element) {
			self.table = table

			selectAllCheckbox = table.querySelector("#select-all")
			rowCheckboxes = Array(table.querySelectorAll("[id^='row-']"))
			sortButtons = Array(table.querySelectorAll(".table-sort-button"))

			paginationFirstBtn = table.querySelector(".pagination-first")
			paginationPrevBtn = table.querySelector(".pagination-previous")
			paginationNextBtn = table.querySelector(".pagination-next")
			paginationLastBtn = table.querySelector(".pagination-last")

			bindEvents()
		}

		private func bindEvents() {
			// Select all checkbox
			if let selectAll = selectAllCheckbox {
				_ = selectAll.on(.change) { [self] _ in
					self.toggleSelectAll()
				}
			}

			// Row checkboxes
			for checkbox in rowCheckboxes {
				_ = checkbox.on(.change) { [self] _ in
					self.updateRowSelection()
				}
			}

			// Sort buttons
			for button in sortButtons {
				_ = button.on(.click) { [self] _ in
					guard let columnId = button.getAttribute("data-column-id") else { return }
					self.toggleSort(columnId: columnId)
				}
			}

			// Pagination buttons
			if let firstBtn = paginationFirstBtn {
				_ = firstBtn.on(.click) { [self] _ in
					self.goToPage(1)
				}
			}

			if let prevBtn = paginationPrevBtn {
				_ = prevBtn.on(.click) { [self] _ in
					self.goToPage(self.currentPage - 1)
				}
			}

			if let nextBtn = paginationNextBtn {
				_ = nextBtn.on(.click) { [self] _ in
					self.goToPage(self.currentPage + 1)
				}
			}

			if let lastBtn = paginationLastBtn {
				_ = lastBtn.on(.click) { [self] _ in
					self.goToPage(10)
				}
			}
		}

		private func toggleSelectAll() {
			guard let selectAll = selectAllCheckbox else { return }
			let isChecked = selectAll.checked

			for checkbox in rowCheckboxes {
				checkbox.checked = isChecked
			}

			updateRowSelection()
		}

		private func updateRowSelection() {
			selectedRows = []

			for checkbox in rowCheckboxes {
				if checkbox.checked {
					if let idStr = checkbox.getAttribute(.id) {
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

			// Update select all checkbox state
			if let selectAll = selectAllCheckbox {
				if selectedRows.isEmpty {
					selectAll.checked = false
					selectAll.indeterminate = false
				} else if selectedRows.count == rowCheckboxes.count {
					selectAll.checked = true
					selectAll.indeterminate = false
				} else {
					selectAll.checked = false
					selectAll.indeterminate = true
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
			let event = CustomEvent(type: "table-page-change", detail: String(page))
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
