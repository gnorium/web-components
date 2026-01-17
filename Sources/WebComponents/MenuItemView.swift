#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// MenuItem component following Wikimedia Codex design system specification
/// A MenuItem is a selectable option within a Menu.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/menu-item.html
public struct MenuItemView: HTML {
	let id: String
	let value: String
	let disabled: Bool
	let selected: Bool
	let active: Bool
	let highlighted: Bool
	let label: String
	let match: String
	let supportingText: String
	let url: String
	let urlNewTab: Bool
	let icon: String?
	let showThumbnail: Bool
	let thumbnail: Thumbnail?
	let description: String?
	let searchQuery: String
	let boldLabel: Bool
	let hideDescriptionOverflow: Bool
	let action: MenuItemAction
	let multiselect: Bool
	let content: [HTML]
	let `class`: String

	public struct Thumbnail: Sendable {
		let url: String
		let alt: String

		public init(url: String, alt: String = "") {
			self.url = url
			self.alt = alt
		}
	}

	public enum MenuItemAction: String, Sendable {
		case `default`
		case destructive
	}

	/// Data structure for menu items
	public struct MenuItemData: Sendable {
		let value: String
		let label: String?
		let description: String?
		let icon: String?
		let thumbnail: String?
		let disabled: Bool

		public init(
			value: String,
			label: String? = nil,
			description: String? = nil,
			icon: String? = nil,
			thumbnail: String? = nil,
			disabled: Bool = false
		) {
			self.value = value
			self.label = label
			self.description = description
			self.icon = icon
			self.thumbnail = thumbnail
			self.disabled = disabled
		}
	}

	public init(
		id: String,
		value: String,
		disabled: Bool = false,
		selected: Bool = false,
		active: Bool = false,
		highlighted: Bool = false,
		label: String = "",
		match: String = "",
		supportingText: String = "",
		url: String = "",
		urlNewTab: Bool = false,
		icon: String? = nil,
		showThumbnail: Bool = false,
		thumbnail: Thumbnail? = nil,
		description: String? = nil,
		searchQuery: String = "",
		boldLabel: Bool = false,
		hideDescriptionOverflow: Bool = false,
		action: MenuItemAction = .default,
		multiselect: Bool = false,
		class: String = "",
		@HTMLBuilder content: () -> [HTML] = { [] }
	) {
		self.id = id
		self.value = value
		self.disabled = disabled
		self.selected = selected
		self.active = active
		self.highlighted = highlighted
		self.label = label
		self.match = match
		self.supportingText = supportingText
		self.url = url
		self.urlNewTab = urlNewTab
		self.icon = icon
		self.showThumbnail = showThumbnail
		self.thumbnail = thumbnail
		self.description = description
		self.searchQuery = searchQuery
		self.boldLabel = boldLabel
		self.hideDescriptionOverflow = hideDescriptionOverflow
		self.action = action
		self.multiselect = multiselect
		self.`class` = `class`
		self.content = content()
	}

	@CSSBuilder
	private func menuItemViewCSS(_ disabled: Bool, _ selected: Bool, _ active: Bool, _ highlighted: Bool, _ action: MenuItemAction) -> [CSS] {
		display(.flex)
		alignItems(.center)
		gap(spacing12)
		padding(spacing8, spacing12)
		minHeight(minSizeInteractivePointer)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightSmall22)
		color(disabled ? colorDisabled : (action == .destructive ? colorDestructive : colorSubtle))
		backgroundColor(backgroundColorTransparent)
		border(borderWidthBase, .solid, disabled ? borderColorDisabled : borderColorSubtle)
		borderRadius(borderRadiusBase)
		cursor(disabled ? cursorBaseDisabled : cursorBase)
		userSelect(.none)
		textDecoration(.none)
		boxSizing(.borderBox)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

		if highlighted && !disabled {
			color(colorProgressive)
			border(borderWidthBase, .solid, borderColorProgressive)
		}

		if active && !disabled {
			color(colorProgressive)
			border(borderWidthBase, .solid, borderColorProgressive)
		}

		if !disabled {
			pseudoClass(.hover) {
				color(colorProgressive).important()
				border(borderWidthBase, .solid, borderColorProgressive).important()
				cursor(cursorBaseHover).important()
			}

			pseudoClass(.active) {
				color(colorProgressive).important()
				border(borderWidthBase, .solid, borderColorProgressive).important()
				cursor(cursorBaseHover).important()
			}

			pseudoClass(.focus) {
				color(colorProgressiveFocus).important()
				outline(borderWidthBase, .solid, borderColorProgressiveFocus).important()
				outlineOffset(px(-1)).important()
			}
		}
	}

	@CSSBuilder
	private func menuItemCheckboxCSS(_ selected: Bool) -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconMedium)
		height(sizeIconMedium)
		flexShrink(0)
		border(borderWidthBase, .solid, borderColorInputBinary)
		borderRadius(borderRadiusBase)
		backgroundColor(selected ? backgroundColorInputBinaryChecked : backgroundColorBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
	}

	@CSSBuilder
	private func menuItemCheckmarkCSS() -> [CSS] {
		fontSize(fontSizeSmall14)
		color(colorInvertedFixed)
		lineHeight(1)
	}

	@CSSBuilder
	private func menuItemThumbnailCSS() -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		width(px(40))
		height(px(40))
		flexShrink(0)
		borderRadius(borderRadiusBase)
		overflow(.hidden)
		backgroundColor(backgroundColorNeutralSubtle)
	}

	@CSSBuilder
	private func menuItemThumbnailImageCSS() -> [CSS] {
		width(perc(100))
		height(perc(100))
		objectFit(.cover)
	}

	@CSSBuilder
	private func menuItemThumbnailPlaceholderCSS() -> [CSS] {
		fontSize(fontSizeLarge18)
		color(colorPlaceholder)
	}

	@CSSBuilder
	private func menuItemIconCSS() -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconMedium)
		height(sizeIconMedium)
		flexShrink(0)
		color(colorSubtle)
		fontSize(fontSizeLarge18)
	}

	@CSSBuilder
	private func menuItemTextCSS() -> [CSS] {
		display(.flex)
		flexDirection(.column)
		gap(spacing4)
		flex(1)
		minWidth(0)
	}

	@CSSBuilder
	private func menuItemTitleCSS() -> [CSS] {
		display(.flex)
		alignItems(.baseline)
		gap(spacing4)
		flexWrap(.wrap)
	}

	@CSSBuilder
	private func menuItemLabelCSS(_ boldLabel: Bool, _ hasSearchQuery: Bool) -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(boldLabel || hasSearchQuery ? fontWeightBold : fontWeightNormal)
		lineHeight(lineHeightSmall22)
		color(colorBase)
		wordWrap(.breakWord)
	}

	@CSSBuilder
	private func menuItemSearchQueryCSS() -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightNormal)
		lineHeight(lineHeightSmall22)
		color(colorBase)
	}

	@CSSBuilder
	private func menuItemMatchCSS() -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightNormal)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
	}

	@CSSBuilder
	private func menuItemSupportingTextCSS() -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightNormal)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
	}

	@CSSBuilder
	private func menuItemDescriptionCSS(_ hideOverflow: Bool) -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)

		if hideOverflow {
			overflow(.hidden)
			textOverflow(.ellipsis)
			whiteSpace(.nowrap)
		} else {
			wordWrap(.breakWord)
		}
	}

	public func render(indent: Int = 0) -> String {
		let hasCustomContent = !content.isEmpty
		let displayLabel = label.isEmpty ? value : label
		let hasSearchQuery = !searchQuery.isEmpty
		let hasMatch = !match.isEmpty
		let hasSupportingText = !supportingText.isEmpty
		let hasDescription = description != nil && !(description ?? "").isEmpty
		let hasIcon = icon != nil
		let hasThumbnail = showThumbnail
		let hasUrl = !url.isEmpty

		// Highlight search query in label
		func renderLabelWithHighlight() -> [HTML] {
			if hasSearchQuery && displayLabel.lowercased().contains(searchQuery.lowercased()) {
				let lowerLabel = displayLabel.lowercased()
				let lowerQuery = searchQuery.lowercased()

				if let range = lowerLabel.range(of: lowerQuery) {
					let startIndex = displayLabel.distance(from: displayLabel.startIndex, to: range.lowerBound)
					let endIndex = displayLabel.distance(from: displayLabel.startIndex, to: range.upperBound)

					let beforeQuery = String(displayLabel.prefix(startIndex))
					let queryText = String(displayLabel[displayLabel.index(displayLabel.startIndex, offsetBy: startIndex)..<displayLabel.index(displayLabel.startIndex, offsetBy: endIndex)])
					let afterQuery = String(displayLabel.suffix(displayLabel.count - endIndex))

					return [
						span { beforeQuery }
							.style {
								menuItemLabelCSS(boldLabel, hasSearchQuery)
							},
						span { queryText }
							.class("menu-item-search-query")
							.style {
								menuItemSearchQueryCSS()
							},
						span { afterQuery }
							.style {
								menuItemLabelCSS(boldLabel, hasSearchQuery)
							}
					]
				}
			}

			return [
				span { displayLabel }
					.class("menu-item-label")
					.style {
						menuItemLabelCSS(boldLabel, hasSearchQuery)
					}
			]
		}

		// Main content
		let itemContent: [HTML] = {
			if hasCustomContent {
				return content
			}

			var items: [HTML] = []

			// Multiselect checkbox
			if multiselect {
				items.append(span {
					if selected {
						span { "✓" }
							.class("menu-item-checkmark")
							.ariaHidden(true)
							.style {
								menuItemCheckmarkCSS()
							}
					}
				}
				.class("menu-item-checkbox")
				.style {
					menuItemCheckboxCSS(selected)
				})
			}

			// Thumbnail
			if hasThumbnail {
				if let thumb = thumbnail {
					items.append(span {
						img()
							.src(thumb.url)
							.alt(thumb.alt)
							.class("menu-item-thumbnail-image")
							.style {
								menuItemThumbnailImageCSS()
							}
					}
					.class("menu-item-thumbnail")
					.style {
						menuItemThumbnailCSS()
					})
				} else {
					items.append(span {
						span { icon ?? "📷" }
							.class("menu-item-thumbnail-placeholder")
							.ariaHidden(true)
							.style {
								menuItemThumbnailPlaceholderCSS()
							}
					}
					.class("menu-item-thumbnail")
					.style {
						menuItemThumbnailCSS()
					})
				}
			}

			// Icon (only if not showing thumbnail)
			if hasIcon && !hasThumbnail {
				items.append(span { icon! }
					.class("menu-item-icon")
					.ariaHidden(true)
					.style {
						menuItemIconCSS()
					})
			}

			// Text content
			items.append(span {
				// Title (label + match + supporting text)
				span {
					renderLabelWithHighlight()

					if hasMatch {
						span { " (\(match))" }
							.class("menu-item-match")
							.style {
								menuItemMatchCSS()
							}
					}

					if hasSupportingText {
						span { " \(supportingText)" }
							.class("menu-item-supporting-text")
							.style {
								menuItemSupportingTextCSS()
							}
					}
				}
				.class("menu-item-title")
				.style {
					menuItemTitleCSS()
				}

				// Description
				if hasDescription {
					span { description! }
						.class("menu-item-description")
						.style {
							menuItemDescriptionCSS(hideDescriptionOverflow)
						}
				}
			}
			.class("menu-item-text")
			.style {
				menuItemTextCSS()
			})

			return items
		}()

		// Wrapper element (a or li)
		if hasUrl {
			var link = a {
				itemContent
			}
			.href(url)
			.class(`class`.isEmpty ? "menu-item-view" : "menu-item-view \(`class`)")
			.id(id)
			.role(.option)
			.ariaSelected(selected)
			.ariaDisabled(disabled)
			.data("value", value)

			if highlighted {
				link = link.data("highlighted", "true")
			}

			if active {
				link = link.data("active", "true")
			}

			if urlNewTab {
				link = link.target(.blank).rel(.noopener)
			}

			return link
				.style {
					menuItemViewCSS(disabled, selected, active, highlighted, action)
				}
				.render(indent: indent)
		} else {
			var listItem = li {
				itemContent
			}
			.class(`class`.isEmpty ? "menu-item-view" : "menu-item-view \(`class`)")
			.id(id)
			.role(.option)
			.ariaSelected(selected)
			.ariaDisabled(disabled)
			.data("value", value)

			if highlighted {
				listItem = listItem.data("highlighted", "true")
			}

			if active {
				listItem = listItem.data("active", "true")
			}

			return listItem
				.style {
					menuItemViewCSS(disabled, selected, active, highlighted, action)
				}
				.render(indent: indent)
		}
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

private class MenuItemInstance: @unchecked Sendable {
	private var menuItem: Element

	init(menuItem: Element) {
		self.menuItem = menuItem

		bindEvents()
	}

	private func bindEvents() {
		// Click event
		_ = menuItem.addEventListener(.click) { [self] event in
			// Check if disabled
			if let disabled = self.menuItem.getAttribute("aria-disabled"), stringEquals(disabled, "true") {
				event.preventDefault()
				return
			}

			// Get value
			guard let value = self.menuItem.dataset["value"] else { return }

			// Dispatch change event
			let customEvent = CustomEvent(type: "menu-item-change", detail: value)
			self.menuItem.dispatchEvent(customEvent)
		}

		// Mouse enter for highlighting
		_ = menuItem.addEventListener(.mouseenter) { [self] _ in
			self.menuItem.dataset["highlighted"] = "true"

			let event = CustomEvent(type: "menu-item-highlight", detail: "")
			self.menuItem.dispatchEvent(event)
		}

		// Mouse leave
		_ = menuItem.addEventListener(.mouseleave) { [self] _ in
			self.menuItem.dataset["highlighted"] = "false"
		}

		// Mouse down for active state
		_ = menuItem.addEventListener(.mousedown) { [self] _ in
			self.menuItem.dataset["active"] = "true"
		}

		// Mouse up
		_ = menuItem.addEventListener(.mouseup) { [self] _ in
			self.menuItem.dataset["active"] = "false"
		}
	}
}

public class MenuItemHydration: @unchecked Sendable {
	private var instances: [MenuItemInstance] = []

	public init() {
		hydrateAllMenuItems()
	}

	private func hydrateAllMenuItems() {
		let allMenuItems = document.querySelectorAll(".menu-item-view")

		for menuItem in allMenuItems {
			let instance = MenuItemInstance(menuItem: menuItem)
			instances.append(instance)
		}
	}
}

#endif
