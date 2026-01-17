#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Menu component following Wikimedia Codex design system specification
/// A Menu displays a list of available options, suggestions, or actions.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/menu.html
public struct MenuView: HTML {
	let menuItems: [MenuItemView.MenuItemData]
	let menuGroups: [MenuGroupData]
	let footer: MenuItemView.MenuItemData?
	let selected: [String]
	let expanded: Bool
	let showPending: Bool
	let visibleItemLimit: Int?
	let showThumbnail: Bool
	let boldLabel: Bool
	let hideDescriptionOverflow: Bool
	let searchQuery: String
	let multiselect: Bool
	let pendingContent: [HTML]
	let noResultsContent: [HTML]
	let showNoResultsSlot: Bool?
	let `class`: String

	/// Data structure for menu groups (groups multiple MenuItems)
	public struct MenuGroupData: Sendable {
		let title: String
		let hideTitle: Bool
		let description: String?
		let icon: String?
		let items: [MenuItemView.MenuItemData]

		public init(
			title: String,
			hideTitle: Bool = false,
			description: String? = nil,
			icon: String? = nil,
			items: [MenuItemView.MenuItemData]
		) {
			self.title = title
			self.hideTitle = hideTitle
			self.description = description
			self.icon = icon
			self.items = items
		}
	}

	public init(
		menuItems: [MenuItemView.MenuItemData] = [],
		menuGroups: [MenuGroupData] = [],
		footer: MenuItemView.MenuItemData? = nil,
		selected: [String] = [],
		expanded: Bool = false,
		showPending: Bool = false,
		visibleItemLimit: Int? = nil,
		showThumbnail: Bool = false,
		boldLabel: Bool = false,
		hideDescriptionOverflow: Bool = false,
		searchQuery: String = "",
		multiselect: Bool = false,
		showNoResultsSlot: Bool? = nil,
		class: String = "",
		@HTMLBuilder pending: () -> [HTML] = { [] },
		@HTMLBuilder noResults: () -> [HTML] = { [] }
	) {
		self.menuItems = menuItems
		self.menuGroups = menuGroups
		self.footer = footer
		self.selected = selected
		self.expanded = expanded
		self.showPending = showPending
		self.visibleItemLimit = visibleItemLimit
		self.showThumbnail = showThumbnail
		self.boldLabel = boldLabel
		self.hideDescriptionOverflow = hideDescriptionOverflow
		self.searchQuery = searchQuery
		self.multiselect = multiselect
		self.showNoResultsSlot = showNoResultsSlot
		self.`class` = `class`
		self.pendingContent = pending()
		self.noResultsContent = noResults()
	}

	@CSSBuilder
	private func menuViewCSS(_ expanded: Bool, _ hasVisibleLimit: Bool) -> [CSS] {
		position(.absolute)
		top(perc(100))
		left(0)
		right(0)
		marginTop(spacing4)
		backgroundColor(backgroundColorBase)
		border(borderWidthBase, .solid, borderColorSubtle)
		borderRadius(borderRadiusBase)
		boxShadow(boxShadowMedium)
		zIndex(100)
		minWidth(minWidthMedium)
		maxWidth(maxWidthBase)
		boxSizing(.borderBox)

		if !expanded {
			display(.none).important()
		}

		if hasVisibleLimit {
			overflowY(.auto)
		}
	}

	@CSSBuilder
	private func menuListCSS(_ hasVisibleLimit: Bool, _ visibleItemLimit: Int?) -> [CSS] {
		listStyle(.none)
		margin(0)
		padding(0)

		if let limit = visibleItemLimit, limit > 0 {
			maxHeight(calc(limit * minSizeInteractivePointer))
			overflowY(.auto)
		}
	}

	@CSSBuilder
	private func menuGroupCSS() -> [CSS] {
		listStyle(.none)
		margin(0)
		padding(0)
	}

	@CSSBuilder
	private func menuGroupHeaderCSS(_ hideTitle: Bool) -> [CSS] {
		if !hideTitle {
			display(.flex)
			alignItems(.center)
			gap(spacing8)
			padding(spacing12, spacing12, spacing4, spacing12)
		}
	}

	@CSSBuilder
	private func menuGroupTitleCSS(_ hideTitle: Bool) -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeSmall14)
		fontWeight(fontWeightBold)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
		margin(0)

		if hideTitle {
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
	private func menuGroupDescriptionCSS() -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeXSmall12)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
		margin(0)
	}

	@CSSBuilder
	private func menuGroupDividerCSS() -> [CSS] {
		height(borderWidthBase)
		backgroundColor(borderColorSubtle)
		margin(spacing8, spacing0)
		border(.none)
	}

	@CSSBuilder
	private func menuPendingCSS() -> [CSS] {
		padding(spacing12)
	}

	@CSSBuilder
	private func menuNoResultsCSS() -> [CSS] {
		padding(spacing12)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
		textAlign(.center)
	}

	public func render(indent: Int = 0) -> String {
		let hasVisibleLimit = visibleItemLimit != nil && visibleItemLimit! > 0
		let allItems = menuItems + menuGroups.flatMap { $0.items }
		let hasItems = !allItems.isEmpty
		let shouldShowNoResults = showNoResultsSlot ?? !hasItems
		let hasGroups = !menuGroups.isEmpty
		let hasPendingContent = !pendingContent.isEmpty

		// Render individual menu item using MenuItemView
		func renderMenuItem(_ item: MenuItemView.MenuItemData, itemIndex: Int, isFooter: Bool = false) -> HTML {
			let isSelected = selected.contains(item.value)
			let thumbnail = item.thumbnail != nil ? MenuItemView.Thumbnail(url: item.thumbnail!, alt: "") : nil

			return MenuItemView(
				id: "menu-item-\(itemIndex)",
				value: item.value,
				disabled: item.disabled,
				selected: isSelected,
				label: item.label ?? "",
				icon: item.icon,
				showThumbnail: showThumbnail,
				thumbnail: thumbnail,
				description: item.description,
				searchQuery: searchQuery,
				boldLabel: boldLabel,
				hideDescriptionOverflow: hideDescriptionOverflow,
				multiselect: multiselect,
				class: isFooter ? "menu-footer-item" : ""
			)
		}

		let itemIndex = 0

		return div {
			ul {
				// Pending state
				if showPending {
					li {
						ProgressBarView(inline: true)

						if hasPendingContent && !hasItems {
							div { pendingContent }
								.class("menu-pending-content")
								.style {
									marginTop(spacing8)
									fontFamily(typographyFontSans)
									fontSize(fontSizeMedium16)
									lineHeight(lineHeightSmall22)
									color(colorSubtle)
								}
						}
					}
					.class("menu-pending")
					.style {
						menuPendingCSS()
					}
				}

				// No results message
				if shouldShowNoResults && !noResultsContent.isEmpty && !showPending {
					li {
						noResultsContent
					}
					.class("menu-no-results")
					.style {
						menuNoResultsCSS()
					}
				}

				// Menu groups
				if hasGroups {
					for (index, group) in menuGroups.enumerated() {
						li {
							// Group divider (for visually-hidden titles)
							if group.hideTitle && index > 0 {
								hr()
									.class("menu-group-divider")
									.ariaHidden(true)
									.style {
										menuGroupDividerCSS()
									}
							}

							// Group header
							div {
								h3 { group.title }
									.class("menu-group-title")
									.style {
										menuGroupTitleCSS(group.hideTitle)
									}

								if let desc = group.description {
									p { desc }
										.class("menu-group-description")
										.style {
											menuGroupDescriptionCSS()
										}
								}
							}
							.class("menu-group-header")
							.style {
								menuGroupHeaderCSS(group.hideTitle)
							}

							// Group items
							ul {
								group.items.enumerated().map { (offset, item) in
									let currentIndex = itemIndex + offset
									return renderMenuItem(item, itemIndex: currentIndex)
								}
							}
							.class("menu-group-list")
							.role(.group)
							.ariaLabelledby(group.title)
							.style {
								menuGroupCSS()
							}
						}
						.class("menu-group")
						.style {
							menuGroupCSS()
						}
					}
				}

				// Individual menu items (not in groups)
				if !menuItems.isEmpty {
					menuItems.enumerated().map { (offset, item) in
						renderMenuItem(item, itemIndex: itemIndex + offset)
					}
				}

				// Footer item
				if let footerItem = footer {
					renderMenuItem(footerItem, itemIndex: allItems.count, isFooter: true)
				}
			}
			.class("menu-list")
			.role(multiselect ? .listbox : .listbox)
			.ariaMultiselectable(multiselect)
			.style {
				menuListCSS(hasVisibleLimit, visibleItemLimit)
			}
		}
		.class(`class`.isEmpty ? "menu-view" : "menu-view \(`class`)")
		.data("expanded", expanded ? "true" : "false")
		.style {
			menuViewCSS(expanded, hasVisibleLimit)
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

private class MenuInstance: @unchecked Sendable {
	private var menu: Element
	private var menuItems: [Element] = []
	private var highlightedIndex: Int = -1
	private var multiselect: Bool = false

	init(menu: Element) {
		self.menu = menu

		// Get multiselect state
		if let list = menu.querySelector(".menu-list") {
			if let ariaMulti = list.getAttribute("aria-multiselectable") {
				multiselect = stringEquals(ariaMulti, "true")
			}
		}

		// Get all menu items (MenuItemView instances)
		let items = menu.querySelectorAll(".menu-item-view:not(.menu-footer-item)")
		for item in items {
			menuItems.append(item)
		}

		bindEvents()
	}

	private func bindEvents() {
		// Listen for menu-item-change events from MenuItemView
		for (index, item) in menuItems.enumerated() {
			_ = item.addEventListener("menu-item-change") { [self] event in
				let value = event.detail

				// Get current selection state
				let isSelected = item.getAttribute("aria-selected") ?? "false"
				let newSelected = !stringEquals(isSelected, "true")

				if self.multiselect {
					// Multiselect: toggle this item
					item.setAttribute("aria-selected", newSelected ? "true" : "false")
				} else {
					// Single select: deselect all, select this one
					for otherItem in self.menuItems {
						otherItem.setAttribute("aria-selected", "false")
					}
					item.setAttribute("aria-selected", "true")

					// Close menu
					self.menu.dataset["expanded"] = "false"
					self.menu.style.display(.none)
				}

				// Dispatch selection event from menu
				let menuEvent = CustomEvent(type: "menu-item-select", detail: value)
				self.menu.dispatchEvent(menuEvent)
			}

			// Listen for highlight events
			_ = item.addEventListener("menu-item-highlight") { [self] _ in
				self.highlightedIndex = index
				self.updateHighlight()
			}
		}

		// Scroll event for load-more
		if let list = menu.querySelector(".menu-list") {
			_ = list.addEventListener(.scroll) { [self] _ in
				let scrollTop = list.scrollTop
				let scrollHeight = list.scrollHeight
				let clientHeight = list.clientHeight

				// Near bottom (within 50px)
				if scrollTop + clientHeight >= scrollHeight - 50 {
					let event = CustomEvent(type: "menu-load-more", detail: "")
					self.menu.dispatchEvent(event)
				}
			}
		}
	}

	public func handleKeydown(_ key: String) -> Bool {
		guard !menuItems.isEmpty else { return false }

		switch key {
		case "ArrowDown":
			highlightedIndex = min(highlightedIndex + 1, menuItems.count - 1)
			updateHighlight()
			scrollToHighlighted()
			return true

		case "ArrowUp":
			highlightedIndex = max(highlightedIndex - 1, 0)
			updateHighlight()
			scrollToHighlighted()
			return true

		case "Home":
			highlightedIndex = 0
			updateHighlight()
			scrollToHighlighted()
			return true

		case "End":
			highlightedIndex = menuItems.count - 1
			updateHighlight()
			scrollToHighlighted()
			return true

		case "Enter":
			if highlightedIndex >= 0 && highlightedIndex < menuItems.count {
				let item = menuItems[highlightedIndex]
				// Trigger click on MenuItemView
				item.click()
			}
			return true

		case "Escape":
			menu.dataset["expanded"] = "false"
			menu.style.display(.none)
			return true

		default:
			return false
		}
	}

	private func updateHighlight() {
		for (index, item) in menuItems.enumerated() {
			if index == highlightedIndex {
				item.dataset["highlighted"] = "true"

				// Dispatch keyboard navigation event
				let event = CustomEvent(type: "menu-item-keyboard-nav", detail: "")
				menu.dispatchEvent(event)
			} else {
				item.dataset["highlighted"] = "false"
			}
		}
	}

	private func scrollToHighlighted() {
		guard highlightedIndex >= 0 && highlightedIndex < menuItems.count else { return }
		let item = menuItems[highlightedIndex]

		// Scroll into view if needed
		item.scrollIntoView(.init(block: ScrollIntoViewOptions.nearest, inline: ScrollIntoViewOptions.nearest))
	}

	public func getHighlightedMenuItem() -> Element? {
		guard highlightedIndex >= 0 && highlightedIndex < menuItems.count else { return nil }
		return menuItems[highlightedIndex]
	}
}

public class MenuHydration: @unchecked Sendable {
	private var instances: [MenuInstance] = []

	public init() {
		hydrateAllMenus()
	}

	private func hydrateAllMenus() {
		let allMenus = document.querySelectorAll(".menu-view")

		for menu in allMenus {
			let instance = MenuInstance(menu: menu)
			instances.append(instance)
		}
	}
}

#endif
