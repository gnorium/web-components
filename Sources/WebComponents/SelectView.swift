#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Select component following Wikimedia Codex design system specification
/// A select input with a dropdown menu of predefined, selectable options.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/select.html
public struct SelectView: HTML {
	let id: String
	let name: String
	let menuItems: [MenuItemView.MenuItemData]
	let menuGroups: [MenuView.MenuGroupData]
	let selectedValue: String?
	let defaultLabel: String
	let defaultIcon: String?
	let disabled: Bool
	let status: ValidationStatus
	let visibleItemLimit: Int?
	let `class`: String

	public enum ValidationStatus: String, Sendable {
		case `default`
		case error
	}

	public init(
		id: String,
		name: String,
		menuItems: [MenuItemView.MenuItemData] = [],
		menuGroups: [MenuView.MenuGroupData] = [],
		selectedValue: String? = nil,
		defaultLabel: String = "",
		defaultIcon: String? = nil,
		disabled: Bool = false,
		status: ValidationStatus = .default,
		visibleItemLimit: Int? = nil,
		class: String = ""
	) {
		self.id = id
		self.name = name
		self.menuItems = menuItems
		self.menuGroups = menuGroups
		self.selectedValue = selectedValue
		self.defaultLabel = defaultLabel
		self.defaultIcon = defaultIcon
		self.disabled = disabled
		self.status = status
		self.visibleItemLimit = visibleItemLimit
		self.`class` = `class`
	}

	@CSSBuilder
	private func selectViewCSS() -> [CSS] {
		position(.relative)
		display(.inlineBlock)
		minWidth(px(256))
	}

	@CSSBuilder
	private func selectHandleCSS(_ disabled: Bool, _ status: ValidationStatus) -> [CSS] {
		display(.flex)
		alignItems(.center)
		justifyContent(.spaceBetween)
		gap(spacing8)
		minHeight(minSizeInteractivePointer)
		padding(spacing8, spacing12)
		backgroundColor(disabled ? backgroundColorDisabled : backgroundColorBase)
		border(borderWidthBase, .solid, status == .error ? borderColorError : (disabled ? borderColorDisabled : borderColorInputBinary))
		borderRadius(borderRadiusBase)
		color(disabled ? colorDisabled : colorBase)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightSmall22)
		cursor(disabled ? cursorBaseDisabled : cursorBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		userSelect(.none)

		pseudoClass(.hover, not(.disabled)) {
			borderColor(borderColorInputBinaryHover).important()
		}

		pseudoClass(.focus) {
			borderColor(borderColorProgressiveFocus).important()
			boxShadow(px(0), px(0), px(0), px(1), boxShadowColorProgressiveFocus).important()
			outline(px(1), .solid, .transparent).important()
		}
	}

	@CSSBuilder
	private func selectLabelCSS(_ hasSelection: Bool) -> [CSS] {
		display(.flex)
		alignItems(.center)
		gap(spacing8)
		flex(1)
		overflow(.hidden)
		textOverflow(.ellipsis)
		whiteSpace(.nowrap)

		if !hasSelection {
			color(colorPlaceholder).important()
		}
	}

	@CSSBuilder
	private func selectIconCSS() -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		flexShrink(0)
		width(sizeIconSmall)
		height(sizeIconSmall)
	}

	@CSSBuilder
	private func selectIndicatorCSS(_ disabled: Bool) -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		flexShrink(0)
		width(sizeIconSmall)
		height(sizeIconSmall)
		color(disabled ? colorDisabled : colorSubtle)
	}

	public func render(indent: Int = 0) -> String {
		let selectedItem = menuItems.first(where: { $0.value == selectedValue }) ??
			menuGroups.flatMap(\.items).first(where: { $0.value == selectedValue })

		let displayLabel = selectedItem?.label ?? selectedItem?.value ?? defaultLabel
		let displayIcon = selectedItem?.icon ?? defaultIcon
		let hasSelection = selectedValue != nil

		var selectHandle = div {
			if let icon = displayIcon {
				span { icon }
					.class("select-icon")
					.ariaHidden(true)
					.style {
						selectIconCSS()
					}
			}

			span { displayLabel }
				.class("select-label")
				.style {
					selectLabelCSS(hasSelection)
				}

			span { "▼" }
				.class("select-indicator")
				.ariaHidden(true)
				.style {
					selectIndicatorCSS(disabled)
				}
		}
		.class("select-handle")
		.id(id)
		.role(.combobox)
		.ariaExpanded(false)
		.ariaHaspopup(.listbox)
		.ariaDisabled(disabled)
		.data("name", name)

		if !disabled {
			selectHandle = selectHandle.tabindex(0)
		}

		if let value = selectedValue {
			selectHandle = selectHandle.data("value", value)
		}

		selectHandle = selectHandle.style {
			selectHandleCSS(disabled, status)
		}

		return div {
			selectHandle

			MenuView(
				menuItems: menuItems,
				menuGroups: menuGroups,
				selected: selectedValue != nil ? [selectedValue!] : [],
				expanded: false,
				visibleItemLimit: visibleItemLimit,
				class: "select-menu"
			)
		}
		.class(`class`.isEmpty ? "select-view" : "select-view \(`class`)")
		.style {
			selectViewCSS()
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

private class SelectInstance: @unchecked Sendable {
	private var select: Element
	private var handle: Element?
	private var menu: Element?
	private var isOpen: Bool = false

	init(select: Element) {
		self.select = select

		handle = select.querySelector(".select-handle")
		menu = select.querySelector(".menu-view")

		bindEvents()
	}

	private func bindEvents() {
		guard let handle else { return }

		// Handle click - toggle menu
		_ = handle.addEventListener(.click) { [self] _ in
			guard let ariaDisabled = handle.getAttribute(.ariaDisabled),
				  !stringEquals(ariaDisabled, "true") else { return }

			if self.isOpen {
				self.closeMenu()
			} else {
				self.openMenu()
			}
		}

		// Handle keyboard navigation
		_ = handle.addEventListener(.keydown) { [self] (event: CallbackString) in
			self.handleKeydown(event)
		}

		// Handle blur - close menu (delayed to allow item selection)
		_ = handle.addEventListener(.blur) { [self] _ in
			_ = setTimeout(100) {
				self.closeMenu()
			}
		}

		// Listen for menu-item-select events from MenuView
		if let menu = menu {
			_ = menu.addEventListener("menu-item-select") { [self] event in
				let value = event.detail
				self.selectValue(value)
			}
		}
	}

	private func openMenu() {
		menu?.dataset["expanded"] = "true"
		menu?.style.display(.flex)
		handle?.setAttribute("aria-expanded", "true")
		isOpen = true
	}

	private func closeMenu() {
		menu?.dataset["expanded"] = "false"
		menu?.style.display(.none)
		handle?.setAttribute("aria-expanded", "false")
		isOpen = false
	}

	private func selectValue(_ value: String) {
		guard let handle = handle else { return }

		// Update handle data-value
		handle.dataset["value"] = value

		// Update label (find selected item from MenuView)
		if let selectedItem = menu?.querySelector(".menu-item-view[data-value='\(value)']") {
			if let label = select.querySelector(".select-label"),
			   let itemLabel = selectedItem.querySelector(".menu-item-label") {
				label.textContent = itemLabel.textContent
			}

			// Update icon if present
			if let itemIcon = selectedItem.querySelector(".menu-item-icon"),
			   let iconContent = itemIcon.textContent {
				if let existingIcon = select.querySelector(".select-icon") {
					existingIcon.textContent = iconContent
				}
			}
		}

		// Dispatch change event
		let event = CustomEvent(type: "select-change", detail: value)
		select.dispatchEvent(event)

		closeMenu()
	}

	private func handleKeydown(_ event: CallbackString) {
		event.withCString { eventPtr in
			let key = String(cString: eventPtr)

			if stringEquals(key, "ArrowDown") || stringEquals(key, "ArrowUp") {
				if !isOpen {
					openMenu()
				}
				// MenuView handles keyboard navigation internally
			} else if stringEquals(key, "Enter") {
				if !isOpen {
					openMenu()
				}
				// MenuView handles Enter key
			} else if stringEquals(key, "Escape") {
				if isOpen {
					closeMenu()
					handle?.focus()
				}
				// MenuView handles Home/End keys
			}
		}
	}
}

public class SelectHydration: @unchecked Sendable {
	private var instances: [SelectInstance] = []

	public init() {
		hydrateAllSelects()
	}

	private func hydrateAllSelects() {
		let allSelects = document.querySelectorAll(".select-view")

		for select in allSelects {
			let instance = SelectInstance(select: select)
			instances.append(instance)
		}
	}
}

#endif
