#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Lookup component following Wikimedia Codex design system specification
/// A predictive text input that presents a dropdown menu with suggestions based on the current input value.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/lookup.html
public struct LookupView: HTML {
	let id: String
	let name: String
	let menuItems: [MenuItemView.MenuItemData]
	let selectedValue: String
	let inputValue: String
	let placeholder: String
	let startIcon: String?
	let disabled: Bool
	let readonly: Bool
	let status: ValidationStatus
	let visibleItemLimit: Int?
	let showNoResults: Bool
	let `class`: String

	public enum ValidationStatus: String, Sendable {
		case `default`
		case error
	}

	public init(
		id: String,
		name: String,
		menuItems: [MenuItemView.MenuItemData] = [],
		selectedValue: String = "",
		inputValue: String = "",
		placeholder: String = "",
		startIcon: String? = nil,
		disabled: Bool = false,
		readonly: Bool = false,
		status: ValidationStatus = .default,
		visibleItemLimit: Int? = nil,
		showNoResults: Bool = true,
		class: String = ""
	) {
		self.id = id
		self.name = name
		self.menuItems = menuItems
		self.selectedValue = selectedValue
		self.inputValue = inputValue
		self.placeholder = placeholder
		self.startIcon = startIcon
		self.disabled = disabled
		self.readonly = readonly
		self.status = status
		self.visibleItemLimit = visibleItemLimit
		self.showNoResults = showNoResults
		self.`class` = `class`
	}

	@CSSBuilder
	private func lookupViewCSS() -> [CSS] {
		position(.relative)
		display(.inlineBlock)
		minWidth(px(256))
	}

	public func render(indent: Int = 0) -> String {
		return div {
			TextInputView(
				id: id,
				name: name,
				placeholder: placeholder,
				value: inputValue,
				type: .text,
				status: status == .error ? .error : .default,
				disabled: disabled,
				readonly: readonly,
				startIcon: startIcon
			)

			MenuView(
				menuItems: menuItems,
				selected: [selectedValue],
				expanded: false,
				visibleItemLimit: visibleItemLimit,
				showNoResultsSlot: showNoResults,
				class: "lookup-menu"
			) {
				// No results message
				"No results found"
			}
		}
		.class(`class`.isEmpty ? "lookup-view" : "lookup-view \(`class`)")
		.style {
			lookupViewCSS()
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

private class LookupInstance: @unchecked Sendable {
	private var lookup: Element
	private var input: Element?
	private var menu: Element?
	private var menuItems: [Element] = []
	private var isOpen: Bool = false
	private var currentFocusIndex: Int = -1

	init(lookup: Element) {
		self.lookup = lookup

		input = lookup.querySelector(".text-input-view input")
		menu = lookup.querySelector(".lookup-menu")

		if let menu = menu {
			menuItems = Array(menu.querySelectorAll(".menu-item-view"))
		}

		bindEvents()
	}

	private func bindEvents() {
		guard let input else { return }

		// Input focus - open menu
		_ = input.addEventListener(.focus) { [self] _ in
			self.openMenu()
		}

		// Input blur - close menu (delayed to allow item selection)
		_ = input.addEventListener(.blur) { [self] _ in
			// Delay to allow click on menu item
			_ = setTimeout(100) {
				self.closeMenu()
			}
		}

		// Input typing
		_ = input.addEventListener(.input) { [self] _ in
			self.openMenu()
			// Dispatch input event for filtering
			let event = CustomEvent(type: "lookup-input", detail: input.value)
			self.lookup.dispatchEvent(event)
		}

		// Keyboard navigation
		_ = input.addEventListener(.keydown) { [self] (event: CallbackString) in
			self.handleInputKeydown(event)
		}

		// Menu item clicks
		for (index, item) in menuItems.enumerated() {
			_ = item.addEventListener(.click) { [self] _ in
				self.selectMenuItem(item)
			}

			_ = item.addEventListener(.keydown) { [self] (event: CallbackString) in
				self.handleMenuItemKeydown(event, index: index)
			}

			_ = item.addEventListener(.focus) { [self] _ in
				self.currentFocusIndex = index
			}
		}
	}

	private func openMenu() {
		menu?.style.display(.block)
		isOpen = true
	}

	private func closeMenu() {
		menu?.style.display(.none)
		isOpen = false
		currentFocusIndex = -1
	}

	private func selectMenuItem(_ item: Element) {
		guard let ariaDisabled = item.getAttribute("aria-disabled"),
			  !stringEquals(ariaDisabled, "true") else { return }

		guard let value = item.getAttribute("data-value") else { return }

		// Update input value
		if let input = input {
			input.value = value
		}

		// Emit selection event
		let event = CustomEvent(type: "lookup-select", detail: value)
		lookup.dispatchEvent(event)

		closeMenu()
	}

	private func handleInputKeydown(_ event: CallbackString) {
		event.withCString { eventPtr in
			let key = String(cString: eventPtr)

			if stringEquals(key, "ArrowDown") {
				if !isOpen {
					openMenu()
				} else if !menuItems.isEmpty {
					focusFirstItem()
				}
			} else if stringEquals(key, "ArrowUp") {
				if !isOpen {
					openMenu()
				}
			} else if stringEquals(key, "Escape") {
				if isOpen {
					closeMenu()
				}
			} else if stringEquals(key, "Enter") {
				if isOpen && currentFocusIndex >= 0 && currentFocusIndex < menuItems.count {
					selectMenuItem(menuItems[currentFocusIndex])
				}
			}
		}
	}

	private func handleMenuItemKeydown(_ event: CallbackString, index: Int) {
		event.withCString { eventPtr in
			let key = String(cString: eventPtr)

			if stringEquals(key, "ArrowDown") {
				focusNextItem()
			} else if stringEquals(key, "ArrowUp") {
				focusPreviousItem()
			} else if stringEquals(key, "Home") {
				focusFirstItem()
			} else if stringEquals(key, "End") {
				focusLastItem()
			} else if stringEquals(key, "Escape") {
				closeMenu()
				input?.focus()
			} else if stringEquals(key, "Enter") {
				selectMenuItem(menuItems[index])
			}
		}
	}

	private func focusNextItem() {
		guard !menuItems.isEmpty else { return }
		currentFocusIndex = (currentFocusIndex + 1) % menuItems.count
		menuItems[currentFocusIndex].focus()
	}

	private func focusPreviousItem() {
		guard !menuItems.isEmpty else { return }
		currentFocusIndex = currentFocusIndex - 1
		if currentFocusIndex < 0 {
			currentFocusIndex = menuItems.count - 1
		}
		menuItems[currentFocusIndex].focus()
	}

	private func focusFirstItem() {
		guard !menuItems.isEmpty else { return }
		currentFocusIndex = 0
		menuItems[currentFocusIndex].focus()
	}

	private func focusLastItem() {
		guard !menuItems.isEmpty else { return }
		currentFocusIndex = menuItems.count - 1
		menuItems[currentFocusIndex].focus()
	}
}

public class LookupHydration: @unchecked Sendable {
	private var instances: [LookupInstance] = []

	public init() {
		hydrateAllLookups()
	}

	private func hydrateAllLookups() {
		let allLookups = document.querySelectorAll(".lookup-view")

		for lookup in allLookups {
			let instance = LookupInstance(lookup: lookup)
			instances.append(instance)
		}
	}
}

#endif
