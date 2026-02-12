#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// TypeaheadSearch is a search input that provides a menu of options based on the current search query.
public struct TypeaheadSearchView: HTMLProtocol {
	public struct SearchResult: Sendable {
		public let value: String
		public let label: String
		public let description: String?
		public let url: String?
		public let thumbnail: String?

		public init(
			value: String,
			label: String,
			description: String? = nil,
			url: String? = nil,
			thumbnail: String? = nil
		) {
			self.value = value
			self.label = label
			self.description = description
			self.url = url
			self.thumbnail = thumbnail
		}
	}

	let id: String
	let formAction: String
	let searchResults: [SearchResult]
	let useButton: Bool
	let buttonLabel: String
	let initialInputValue: String
	let searchFooterUrl: String
	let highlightQuery: Bool
	let showThumbnail: Bool
	let autoExpandWidth: Bool
	let visibleItemLimit: Int?
	let showEmptyQueryResults: Bool
	let placeholder: String
	let `class`: String

	public init(
		id: String,
		formAction: String,
		searchResults: [SearchResult] = [],
		useButton: Bool = false,
		buttonLabel: String = "",
		initialInputValue: String = "",
		searchFooterUrl: String = "",
		highlightQuery: Bool = false,
		showThumbnail: Bool = false,
		autoExpandWidth: Bool = false,
		visibleItemLimit: Int? = nil,
		showEmptyQueryResults: Bool = false,
		placeholder: String = "",
		class: String = ""
	) {
		self.id = id
		self.formAction = formAction
		self.searchResults = searchResults
		self.useButton = useButton
		self.buttonLabel = buttonLabel.isEmpty ? "Search" : buttonLabel
		self.initialInputValue = initialInputValue
		self.searchFooterUrl = searchFooterUrl
		self.highlightQuery = highlightQuery
		self.showThumbnail = showThumbnail
		self.autoExpandWidth = autoExpandWidth
		self.visibleItemLimit = visibleItemLimit
		self.showEmptyQueryResults = showEmptyQueryResults
		self.placeholder = placeholder
		self.`class` = `class`
	}

	@CSSBuilder
	private func typeaheadSearchViewCSS() -> [CSSProtocol] {
		position(.relative)
		width(perc(100))
		fontFamily(typographyFontSans)
	}

	@CSSBuilder
	private func typeaheadSearchFormCSS() -> [CSSProtocol] {
		position(.relative)
		width(perc(100))
	}

	@CSSBuilder
	private func typeaheadSearchInputWrapperCSS(_ autoExpandWidth: Bool, _ showThumbnail: Bool) -> [CSSProtocol] {
		position(.relative)
		width(perc(100))

		if autoExpandWidth && showThumbnail {
			transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		}
	}

	@CSSBuilder
	private func typeaheadSearchMenuCSS() -> [CSSProtocol] {
		display(.flex)
		flexDirection(.column)
		gap(spacing8)
		maxHeight(min(calc(vh(100) - px(128)), px(900)))
		overflowY(.auto)
	}

	@CSSBuilder
	private func typeaheadSearchPendingCSS() -> [CSSProtocol] {
		padding(spacing12, spacing16)
		color(colorSubtle)
		fontSize(fontSizeSmall14)
	}

	@CSSBuilder
	private func typeaheadSearchNoResultsCSS() -> [CSSProtocol] {
		padding(spacing12, spacing16)
		color(colorSubtle)
		fontSize(fontSizeSmall14)
		textAlign(.center)
	}

	public func render(indent: Int = 0) -> String {
		let showMenu = !searchResults.isEmpty || showEmptyQueryResults
		let visibleResults = if let limit = visibleItemLimit {
			Array(searchResults.prefix(limit))
		} else {
			searchResults
		}

		return div {
			form {
				div {
					SearchInputView(
						modelValue: initialInputValue,
						useButton: useButton,
						clearable: true,
						buttonLabel: buttonLabel,
						placeholder: placeholder
					)
				}
				.class("typeahead-search-input-wrapper")
				.style {
					typeaheadSearchInputWrapperCSS(autoExpandWidth, showThumbnail)
				}

				if showMenu {
					div {
						MenuView(
							menuItems: visibleResults.map { result in
								MenuItemView.MenuItemData(
									value: result.value,
									label: result.label,
									description: result.description,
									thumbnail: showThumbnail ? result.thumbnail : nil
								)
							} + (searchFooterUrl.isEmpty ? [] : [
								MenuItemView.MenuItemData(
									value: "search-footer",
									label: "Search for \"\(initialInputValue)\""
								)
							]),
							selected: [],
							showThumbnail: showThumbnail
						)
					}
					.class("typeahead-search-menu")
					.style {
						typeaheadSearchMenuCSS()
					}
				}
			}
			.id(id)
			.action(formAction)
			.method(.get)
			.class("typeahead-search-form")
			.style {
				typeaheadSearchFormCSS()
			}
		}
		.class(`class`.isEmpty ? (showThumbnail ? (autoExpandWidth ? "typeahead-search-view typeahead-search-show-thumbnail typeahead-search-auto-expand-width" : "typeahead-search-view typeahead-search-show-thumbnail") : "typeahead-search-view") : (showThumbnail ? (autoExpandWidth ? "typeahead-search-view typeahead-search-show-thumbnail typeahead-search-auto-expand-width \(`class`)" : "typeahead-search-view typeahead-search-show-thumbnail \(`class`)") : "typeahead-search-view \(`class`)"))
		.data("show-empty-query", showEmptyQueryResults ? "true" : "false")
		.data("highlight-query", highlightQuery ? "true" : "false")
		.style {
			typeaheadSearchViewCSS()
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

private class TypeaheadSearchInstance: @unchecked Sendable {
	private var typeaheadSearchElement: Element
	private var formElement: Element?
	private var inputElement: Element?
	private var inputViewElement: Element?
	private var menuElement: Element?
	private var menuItems: [Element] = []
	private var debounceTimer: Int32?
	private var currentQuery: String = ""
	private var selectedIndex: Int = -1
	private var highlightQuery: Bool = false

	init(typeaheadSearch: Element) {
		self.typeaheadSearchElement = typeaheadSearch
		self.formElement = typeaheadSearch.querySelector(".typeahead-search-form")
		self.inputElement = typeaheadSearch.querySelector(".search-input")
		self.inputViewElement = typeaheadSearch.querySelector(".search-input-view")
		self.menuElement = typeaheadSearch.querySelector(".typeahead-search-menu")
		self.highlightQuery = stringEquals(typeaheadSearch.getAttribute("data-highlight-query") ?? "", "true")

		if let menu = menuElement {
			self.menuItems = Array(menu.querySelectorAll(".menu-item-view"))
		}

		bindEvents()
	}

	private func bindEvents() {
		if let input = inputElement {
			_ = input.addEventListener(.input) { [self] _ in
				self.handleInput()
			}
		}

		if let view = inputViewElement {
            // Listen for submit-click from SearchInputInstance
            _ = view.addEventListener("submit-click") { [self] _ in
                self.handleSubmit()
            }

			// Listen for arrow navigation from SearchInputInstance
			_ = view.addEventListener("arrow-down") { [self] _ in
				console.log("TypeaheadSearchView: Received arrow-down event")
				self.handleKeydown(key: "ArrowDown")
			}

			_ = view.addEventListener("arrow-up") { [self] _ in
				console.log("TypeaheadSearchView: Received arrow-up event")
				self.handleKeydown(key: "ArrowUp")
			}
		}

		for (index, item) in menuItems.enumerated() {
			_ = item.addEventListener(.click) { [self] _ in
				self.selectResult(index: index)
			}

			_ = item.addEventListener(.mouseenter) { [self] _ in
				self.selectedIndex = index
				self.updateMenuItemStates()
			}
		}

		if let form = formElement {
			_ = form.addEventListener(.submit) { [self] event in
				event.preventDefault()
				self.handleSubmit()
			}
		}

		// Listen for menu updates from manual DOM manipulation (e.g. via SearchDialogView)
		_ = typeaheadSearchElement.addEventListener("typeahead-menu-updated") { [self] _ in
			self.handleMenuUpdate()
		}
	}

	private func handleMenuUpdate() {
		guard let menu = menuElement else { return }
		self.menuItems = Array(menu.querySelectorAll(".menu-item-view"))

		// Re-bind events for new items
		for (index, item) in menuItems.enumerated() {
			_ = item.addEventListener(.click) { [self] _ in
				self.selectResult(index: index)
			}

			_ = item.addEventListener(.mouseenter) { [self] _ in
				self.selectedIndex = index
				self.updateMenuItemStates()
			}
		}

		// Show menu if we have items
		if !menuItems.isEmpty {
			showMenu()
		} else {
			hideMenu()
		}
	}

	private func handleInput() {
		guard let input = inputElement else { return }
		currentQuery = input.value

		// Debounce input
		if let timer = debounceTimer {
			clearTimeout(timer)
		}

		debounceTimer = setTimeout(250) { [self] in
			self.emitInputEvent()
		}
	}

	private func emitInputEvent() {
		let event = CustomEvent(type: "input", detail: currentQuery)
		typeaheadSearchElement.dispatchEvent(event)

		// Show/hide menu based on query
		if currentQuery.isEmpty {
			let showEmptyQuery = stringEquals(typeaheadSearchElement.getAttribute("data-show-empty-query") ?? "", "true")
			if showEmptyQuery {
				showMenu()
			} else {
				hideMenu()
			}
		} else {
			showMenu()
		}
	}

	private func handleKeydown(key: String) {
		console.log("TypeaheadSearchView: handleKeydown called with key: \(key), menuItems.count: \(menuItems.count), selectedIndex: \(selectedIndex)")

		if stringEquals(key, "ArrowDown") {
			if selectedIndex < menuItems.count - 1 {
				selectedIndex += 1
				console.log("TypeaheadSearchView: ArrowDown - new selectedIndex: \(selectedIndex)")
				updateMenuItemStates()
				scrollToSelected()
			}
		} else if stringEquals(key, "ArrowUp") {
			if selectedIndex > 0 {
				selectedIndex -= 1
				console.log("TypeaheadSearchView: ArrowUp - new selectedIndex: \(selectedIndex)")
				updateMenuItemStates()
				scrollToSelected()
			}
		} else if stringEquals(key, "Enter") {
			if selectedIndex >= 0 && selectedIndex < menuItems.count {
				selectResult(index: selectedIndex)
			}
		} else if stringEquals(key, "Escape") || stringEquals(key, "Esc") {
			hideMenu()
			selectedIndex = -1
			updateMenuItemStates()
		}
	}

	private func selectResult(index: Int) {
		guard index >= 0 && index < menuItems.count else { return }
		let item = menuItems[index]

		if let url = item.getAttribute("data-url"), !url.isEmpty {
			window.location.href = url
		}

		let value = item.getAttribute("data-value") ?? ""
		let event = CustomEvent(type: "search-result-click", detail: value)
		typeaheadSearchElement.dispatchEvent(event)
	}

	private func handleSubmit() {
		let event = CustomEvent(type: "submit", detail: currentQuery)
		typeaheadSearchElement.dispatchEvent(event)
	}

	private func showMenu() {
		guard let menu = menuElement else { return }
		menu.removeAttribute("hidden")
		menu.style.display(.flex)
	}

	private func hideMenu() {
		guard let menu = menuElement else { return }
		menu.setAttribute("hidden", "")
		menu.style.display(.none)
	}

	private func updateMenuItemStates() {
		for (index, item) in menuItems.enumerated() {
			if index == selectedIndex {
				_ = item.classList.add("menu-item-selected")
				item.setAttribute("aria-selected", "true")
				// Apply highlighted styles
				item.style.color(colorBlue)
				item.style.border(borderWidthBase, .solid, borderColorBlue)
			} else {
				_ = item.classList.remove("menu-item-selected")
				item.setAttribute("aria-selected", "false")
				// Apply default styles
				item.style.color(colorSubtle)
				item.style.border(borderWidthBase, .solid, borderColorSubtle)
			}
		}
	}

	private func scrollToSelected() {
		guard selectedIndex >= 0 && selectedIndex < menuItems.count,
		      let menu = menuElement else { return }

		let selectedItem = menuItems[selectedIndex]
		guard let menuRect = menu.getBoundingClientRect(),
		      let itemRect = selectedItem.getBoundingClientRect() else { return }

		if itemRect.bottom > menuRect.bottom {
			menu.scrollTop = menu.scrollTop + (itemRect.bottom - menuRect.bottom)
		} else if itemRect.top < menuRect.top {
			menu.scrollTop = menu.scrollTop - (menuRect.top - itemRect.top)
		}
	}
}

public class TypeaheadSearchHydration: @unchecked Sendable {
	private var instances: [TypeaheadSearchInstance] = []

	public init() {
		hydrateAllTypeaheadSearches()
	}

	private func hydrateAllTypeaheadSearches() {
		let allTypeaheadSearches = document.querySelectorAll(".typeahead-search-view")

		for typeaheadSearch in allTypeaheadSearches {
			let instance = TypeaheadSearchInstance(typeaheadSearch: typeaheadSearch)
			instances.append(instance)
		}
	}
}

#endif
