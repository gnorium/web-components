#if !os(WASI)

import CSSBuilder
import DesignTokens
import HTMLBuilder
import WebTypes

/// Generic list view component for displaying data in a table format.
/// Supports header, search, empty state, and customizable row actions.
///
/// This component is designed to be reusable for any list/table display needs.
public struct ListView: HTML {
	/// Data row representation
	public struct Row: Sendable {
		public let id: String
		public let cells: [String: String]
		
		public init(id: String, cells: [String: String]) {
			self.id = id
			self.cells = cells
		}
	}
	
	/// Action button configuration for row actions
	public struct RowAction: Sendable {
		public let label: String
		public let hrefPattern: String  // Use {id} and {field} placeholders
		public let destructive: Bool
		public let openInNewTab: Bool
		public let className: String?
		
		public init(
			label: String,
			hrefPattern: String,
			destructive: Bool = false,
			openInNewTab: Bool = false,
			className: String? = nil
		) {
			self.label = label
			self.hrefPattern = hrefPattern
			self.destructive = destructive
			self.openInNewTab = openInNewTab
			self.className = className
		}
		
		/// Standard edit action
		public static func edit(pattern: String) -> RowAction {
			RowAction(label: "Edit", hrefPattern: pattern)
		}
		
		/// Standard view action
		public static func view(pattern: String) -> RowAction {
			RowAction(label: "View", hrefPattern: pattern, openInNewTab: true)
		}
		
		/// Standard delete action
		public static func delete(pattern: String) -> RowAction {
			RowAction(label: "Delete", hrefPattern: pattern, destructive: true, className: "list-delete-action")
		}
	}
	
	let title: String
	let columns: [String]
	let columnLabels: [String: String]
	let rows: [Row]
	let actions: [RowAction]
	let createUrl: String?
	let createLabel: String
	let searchPlaceholder: String?
	let emptyMessage: String
	let emptyCreateLabel: String?
	
	public init(
		title: String,
		columns: [String],
		columnLabels: [String: String] = [:],
		rows: [Row],
		actions: [RowAction] = [],
		createUrl: String? = nil,
		createLabel: String = "+ New",
		searchPlaceholder: String? = nil,
		emptyMessage: String = "No items found",
		emptyCreateLabel: String? = nil
	) {
		self.title = title
		self.columns = columns
		self.columnLabels = columnLabels
		self.rows = rows
		self.actions = actions
		self.createUrl = createUrl
		self.createLabel = createLabel
		self.searchPlaceholder = searchPlaceholder
		self.emptyMessage = emptyMessage
		self.emptyCreateLabel = emptyCreateLabel
	}
	
	public func render(indent: Int = 0) -> String {
		div {
			// Header
			header {
				h1 { title }
					.style {
						fontFamily(typographyFontSerif)
						fontSize(px(32))
						fontWeight(.normal)
						color(colorBase)
						margin(0)
					}
				
				if let url = createUrl {
					a { createLabel }
						.href(url)
						.style {
							padding(spacing12, spacing24)
							fontFamily(typographyFontSans)
							fontSize(fontSizeMedium16)
							fontWeight(500)
							color(colorInverted)
							backgroundColor(backgroundColorProgressive)
							border(.none)
							borderRadius(borderRadiusBase)
							textDecoration(.none)
							transition(.backgroundColor, transitionDurationBase, transitionTimingFunctionSystem)
							
							pseudoClass(.hover) {
								backgroundColor(backgroundColorProgressiveHover)
							}
						}
				}
			}
			.class("list-header")
			.style {
				display(.flex)
				justifyContent(.spaceBetween)
				alignItems(.center)
				marginBottom(spacing32)
			}
			
			// Search
			if let placeholder = searchPlaceholder {
				div {
					input()
						.type(.search)
						.name("q")
						.placeholder(placeholder)
						.class("list-search-input")
						.style {
							width(perc(100))
							maxWidth(px(400))
							padding(spacing12, spacing16)
							fontFamily(typographyFontSans)
							fontSize(fontSizeMedium16)
							color(colorBase)
							backgroundColor(backgroundColorBase)
							border(borderWidthBase, borderStyleBase, borderColorBase)
							borderRadius(borderRadiusBase)
							
							pseudoClass(.focus) {
								borderColor(borderColorProgressiveFocus)
								outline(.none)
								boxShadow(.inset, 0, 0, 0, px(1), borderColorProgressiveFocus)
							}
						}
				}
				.class("list-search")
				.style { marginBottom(spacing24) }
			}
			
			// Content
			if rows.isEmpty {
				// Empty state
				div {
					p { emptyMessage }
						.style {
							fontFamily(typographyFontSerif)
							fontSize(fontSizeLarge18)
							color(colorSubtle)
							marginBottom(spacing16)
						}
					
					if let url = createUrl {
						a { emptyCreateLabel ?? "Create First Item" }
							.href(url)
							.style {
								padding(spacing12, spacing24)
								fontFamily(typographyFontSans)
								fontSize(fontSizeMedium16)
								color(colorProgressive)
								backgroundColor(backgroundColorProgressiveSubtle)
								border(borderWidthBase, borderStyleBase, borderColorProgressive)
								borderRadius(borderRadiusBase)
								textDecoration(.none)
								transition(.backgroundColor, transitionDurationBase, transitionTimingFunctionSystem)
								
								pseudoClass(.hover) {
									backgroundColor(backgroundColorProgressiveSubtleHover)
								}
							}
					}
				}
				.class("list-empty")
				.style {
					textAlign(.center)
					padding(spacing48)
					backgroundColor(backgroundColorNeutralSubtle)
					borderRadius(borderRadiusBase)
				}
			} else {
				// Table
				table {
					thead {
						tr {
							for col in columns {
								th { columnLabels[col] ?? col.capitalized }
									.style { thStyle() }
							}
							if !actions.isEmpty {
								th { "Actions" }
									.style { thStyle() }
							}
						}
					}
					
					tbody {
						for row in rows {
							tr {
								for col in columns {
									td { row.cells[col] ?? "" }
										.style { tdStyle() }
								}
								if !actions.isEmpty {
									td {
										div {
											for action in actions {
												buildActionLink(action: action, row: row)
											}
										}
										.style {
											display(.flex)
											gap(spacing8)
										}
									}
									.style { tdStyle() }
								}
							}
							.style {
								pseudoClass(.hover) {
									backgroundColor(backgroundColorInteractiveSubtleHover)
								}
							}
						}
					}
				}
				.class("list-table")
				.style {
					width(perc(100))
					borderCollapse(.collapse)
					backgroundColor(backgroundColorBase)
					border(borderWidthBase, borderStyleBase, borderColorBase)
					borderRadius(borderRadiusBase)
				}
			}
		}
		.class("list-view")
		.style {
			maxWidth(px(1280))
			margin(0, .auto)
			padding(spacing48, spacing24)
		}
		.render(indent: indent)
	}
	
	private func resolveHref(_ pattern: String, row: Row) -> String {
		var result = pattern.replacingOccurrences(of: "{id}", with: row.id)
		for (key, value) in row.cells {
			result = result.replacingOccurrences(of: "{\(key)}", with: value)
		}
		return result
	}
	
	private func buildActionLink(action: RowAction, row: Row) -> HTML {
		let href = resolveHref(action.hrefPattern, row: row)
		var link = a { action.label }
			.href(href)
			.style {
				actionLinkStyle(destructive: action.destructive)
			}
		
		if action.openInNewTab {
			link = link.target(.blank)
		}
		if let cls = action.className {
			link = link.class(cls)
		}
		
		return link
	}
	
	@CSSBuilder
	private func thStyle() -> [CSS] {
		textAlign(.left)
		padding(spacing16)
		fontFamily(typographyFontSans)
		fontSize(fontSizeSmall14)
		fontWeight(600)
		color(colorSubtle)
		backgroundColor(backgroundColorNeutralSubtle)
		borderBottom(borderWidthBase, borderStyleBase, borderColorBase)
	}
	
	@CSSBuilder
	private func tdStyle() -> [CSS] {
		padding(spacing16)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		color(colorBase)
		borderBottom(borderWidthBase, borderStyleBase, borderColorBase)
	}
	
	@CSSBuilder
	private func actionLinkStyle(destructive: Bool) -> [CSS] {
		padding(spacing8, spacing12)
		fontSize(fontSizeSmall14)
		color(destructive ? colorDestructive : colorProgressive)
		textDecoration(.none)
		border(borderWidthBase, borderStyleBase, borderColorBase)
		borderRadius(borderRadiusBase)
		transition(.backgroundColor, transitionDurationBase, transitionTimingFunctionSystem)
		
		pseudoClass(.hover) {
			backgroundColor(destructive ? backgroundColorErrorSubtle : backgroundColorInteractive)
		}
	}
}

#endif
