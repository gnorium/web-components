#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import Foundation
import DesignTokens
import WebTypes

public struct SearchBarView: HTML {
	let inSidebar: Bool
	let openDialog: Bool
	let `class`: String
	let style: [CSS]
	let placeholder: String
	let ariaLabel: String
	let searchField: String
	let searchEndpoint: String
	let resultUrlBase: String

	public init(
		inSidebar: Bool = false,
		openDialog: Bool = false,
		class: String = "",
		placeholder: String = "Search",
		ariaLabel: String = "Search",
		searchField: String = "q",
		searchEndpoint: String = "/api/search",
		resultUrlBase: String = "/results",
		@CSSBuilder style: () -> [CSS] = { [] }
	) {
		self.inSidebar = inSidebar
		self.openDialog = openDialog
		self.class = `class`
		self.placeholder = placeholder
		self.ariaLabel = ariaLabel
		self.searchField = searchField
		self.searchEndpoint = searchEndpoint
		self.resultUrlBase = resultUrlBase
		self.style = style()
	}
	
	public func style(@CSSBuilder _ content: () -> [CSS]) -> SearchBarView {
		return SearchBarView(
			inSidebar: self.inSidebar,
			openDialog: self.openDialog,
			class: self.class,
			placeholder: self.placeholder,
			ariaLabel: self.ariaLabel,
			searchField: self.searchField,
			searchEndpoint: self.searchEndpoint,
			resultUrlBase: self.resultUrlBase,
			style: { self.style + content() }
		)
	}
	
	public func render(indent: Int = 0) -> String {
		div {
			// Input - if openDialog is true, make it read-only and use it as a trigger
			input()
			.type(.search)
			.name(searchField)
			.class("search-bar-input")
			.placeholder(placeholder)
			.ariaLabel(ariaLabel)
			.autocomplete(.off)
			.data("search-input", true)
			.data("search-trigger", openDialog ? "true" : "false")
			.data("search-field", searchField)
			.data("search-endpoint", searchEndpoint)
			.data("result-url-base", resultUrlBase)
			.readonly(openDialog)
			.style {
				border(px(1), .solid, borderColorBase)
				color(colorBase)
				fontFamily(typographyFontSans)
				borderRadius(borderRadiusBase)
				padding(0, calc(rem(1) + px(32)), 0, rem(1)) // Corrected interpolation
				width(perc(100))
				maxWidth(px(512))
				height(px(48))
				fontWeight(fontWeightNormal)
				transition(.all, s(0.2), .easeInOut)
				fontSize(fontSizeSmall14)
				boxSizing(.borderBox)
				backgroundColor(backgroundColorBase)

				if openDialog {
					cursor(.pointer)
				}

				pseudoClass(.active) {
					outline(.none).important()
				}

				pseudoClass(.focus) {
					backgroundColor(backgroundColorBase)
					color(colorBase)
					borderColor(borderColorBase)
					outline(.none)
				}

				pseudoElement(.placeholder) {
					color(colorBase).important()
				}

				media(maxWidth(px(480))) {
					width(px(32))
					padding(0)
				}
			}
			
			// Button
			button {
				SearchIconView()
			}
			.type(.button)
			.class("search-bar-button")
			.ariaLabel("Search")
			.data("search-button", true)
			.style {
				position(.absolute)
				right(0)
				top(perc(50))
				transform(translateY("-\(perc(50))"))
				background(.transparent)
				border(.none)
				color(colorBase)
				marginRight(rem(1))
				paddingLeft(0)
				display(.flex)
				alignItems(.center)
				justifyContent(.center)
				width(px(24))
				height(px(24))
				cursor(.pointer)
				transition(.all, s(0.2), .easeInOut)
				
				pseudoClass(.hover) {
					transform(translateY("-\(perc(50))"), scale(1.02))
					backgroundColor(.transparent).important()
				}
				
				pseudoClass(.active) {
					transform(translateY("-\(perc(50))"), scale(0.95))
					outline(.none)
				}
				
				pseudoClass(.focus) {
					outline(.none)
				}
				
				media(maxWidth(px(480))) {
					paddingLeft(rem(0.5))
				}
			}
			
			// Dropdown
			div {
				ul {
					// Results dynamically inserted by client (WASM hydration)
					// li.search-bar-suggestion-item
					//   a.search-bar-suggestion-link
					//     span.search-bar-suggestion-text (lemma)
					//     span.search-bar-suggestion-language (language badge)
					// Styles applied directly via WebAPIs DSL in render() below
				}
				.class("search-bar-suggestions")
				.role(.listbox)
				.style {
					listStyle(.none)
					margin(0)
					padding(spacing8, 0)
				}
			}
			.class("search-bar-dropdown")
			.data("search-dropdown", true)
		}
		.class(buildClass())
		.data("search-container", true)
		.style {
			display(.flex)
			alignItems(.center)
			position(.relative)
			width(perc(100))
			height(px(48))
			flex(1)
			boxSizing(.borderBox)
			
			for sty in style {
				sty
			}
		}
		.render(indent: indent)
	}

	private func buildClass() -> String {
		var classes = ["search-bar-view"]
		if inSidebar { classes.append("in-sidebar") }
		if openDialog { classes.append("open-dialog") }
		if !`class`.isEmpty { classes.append(`class`) }
		return classes.joined(separator: " ")
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

public class SearchBarHydration: @unchecked Sendable {
	private var container: Element?
	private var input: Element?
	private var button: Element?
	private var dropdown: Element?
	private var searchBarSuggestions: Element?

	private var query = ""
	private var results: [SearchBarSuggestedLemma] = []
	private var isOpen = false
	private var activeIndex = -1
	private var debounceTimer: Int32?
	private var searchField: String = ""
	private var searchEndpoint: String = ""
	private var resultUrlBase: String = ""

	private enum Constants {
		static let debounceMs = 250.0
	}

	public init?() {
		container = document.querySelector("[data-search-container=\"true\"]")
		guard let container else { return nil }

		input = container.querySelector("[data-search-input=\"true\"]")
		guard input != nil else { return nil }

		// Read configuration from data attributes
		searchField = input?.dataset.get("searchField") ?? "q"
		searchEndpoint = input?.dataset.get("searchEndpoint") ?? "/api/search"
		resultUrlBase = input?.dataset.get("resultUrlBase") ?? "/results"

		button = container.querySelector("[data-search-button=\"true\"]")
		guard button != nil else { return nil }

		dropdown = container.querySelector("[data-search-dropdown=\"true\"]")
		guard let dropdown else { return nil }

		searchBarSuggestions = dropdown.querySelector(".search-bar-suggestions")
		guard searchBarSuggestions != nil else { return nil }

		bindEvents()
	}

	private func bindEvents() {
		guard let input, let button else { return }

		// Check if this is a search trigger (opens dialog) or regular search bar (inline search)
		let isTrigger = stringEquals(input.dataset.searchTrigger ?? "", "true")

		if isTrigger {
			// openDialog mode: clicking opens the search dialog
			_ = input.on(.click) { [self] _ in
				self.openSearchDialog()
			}

			_ = button.on(.click) { [self] _ in
				self.openSearchDialog()
			}
		} else {
			// Inline search mode: normal search bar functionality
			_ = input.on(.input) { [self] _ in
				self.onInput()
			}

			_ = input.on(.focus) { [self] _ in
				self.onFocus()
			}

			_ = input.on(.keydown) { [self] key in
				self.onKeyDown(key: key)
			}

			_ = button.on(.click) { [self] _ in
				self.onSearch()
			}

			document.addEventListener(.click) { [self] _ in
				self.isOpen = false
				self.render()
			}
		}
	}

	private func openSearchDialog() {
		// Open the search dialog by dispatching a custom event
		let event = document.createCustomEvent("open-search-dialog", detail: "{}")
		document.dispatchEvent(event)
	}

	private func onInput() {
		if let timerId = debounceTimer {
			window.clearTimeout(timerId)
		}
		debounceTimer = window.setTimeout(Constants.debounceMs) { [self] in
			self.fetchResults()
		}
	}

	private func onFocus() {
		if !results.isEmpty {
			isOpen = true
			render()
		}
	}

	private func onKeyDown(key: CallbackString) {
		guard isOpen else { return }

		// Compare keys using CallbackString.equals
		if key.equals("ArrowDown") {
			activeIndex = (activeIndex + 1) % results.count
			render()
			return
		}

		if key.equals("ArrowUp") {
			activeIndex = (activeIndex - 1 + results.count) % results.count
			render()
			return
		}

		if key.equals("Enter") {
			onSearch()
			return
		}

		if key.equals("Escape") {
			isOpen = false
			render()
			return
		}
	}

	private func cStringEquals(_ ptr1: UnsafePointer<CChar>, _ ptr2: UnsafePointer<CChar>, _ length: Int) -> Bool {
		for i in 0..<length {
			if ptr1[i] != ptr2[i] { return false }
		}
		return ptr1[length] == 0
	}

	private func onSearch() {
		guard activeIndex >= 0 && activeIndex < results.count else { return }
		let result = results[activeIndex]

		let href = "\(resultUrlBase)/\(result.languageCode)/\(result.text)/\(result.homograph)"
		location.href = href
	}

	private func fetchResults() {
		guard let input else { return }
		let query = input.value
		guard !query.isEmpty else {
			results = []
			isOpen = false
			render()
			return
		}
		self.query = query

		let url = "\(searchEndpoint)?value=\(query)&field=\(searchField)"

		input.fetch(url) { [self] jsonString in
			guard let json = jsonString else {
				console.error("SearchBar: Failed to fetch")
				self.results = []
				self.isOpen = false
				self.render()
				return
			}

			// Parse JSON response manually
			if let parsed = self.parseSearchResponse(json) {
				self.results = parsed
				self.isOpen = !parsed.isEmpty
				self.activeIndex = -1
				self.render()
			} else {
				console.error("SearchBar: Failed to parse JSON")
				self.results = []
				self.isOpen = false
				self.render()
			}
		}
	}

	private func render() {
		guard let dropdown else { return }
		guard let searchBarSuggestions = searchBarSuggestions else { return }

		dropdown.style.display(isOpen ? .block : .none)
		searchBarSuggestions.innerHTML = ""

		for (index, result) in results.enumerated() {
			// Create text span with lemma
			let textSpan = document.createElement(.span)
			textSpan.className = "search-bar-suggestion-text"
			textSpan.innerHTML = result.text
			textSpan.style.flex(1)
			textSpan.style.fontSize(px(14))
			textSpan.style.fontWeight(500)
			textSpan.style.whiteSpace(.nowrap)
			textSpan.style.overflow(.hidden)
			textSpan.style.textOverflow(.ellipsis)

			// Create language badge span
			let langSpan = document.createElement(.span)
			langSpan.className = "search-bar-suggestion-language"
			langSpan.innerHTML = result.language
			langSpan.style.display(.inlineBlock)
			langSpan.style.backgroundColor(rgba(0, 0, 0, 0.06))
			langSpan.style.color(rgba(0, 0, 0, 0.7))
			langSpan.style.padding(px(2), px(8))
			langSpan.style.borderRadius(px(12))
			langSpan.style.fontSize(px(12))
			langSpan.style.fontWeight(500)
			langSpan.style.whiteSpace(.nowrap)
			langSpan.style.flexShrink(0)

			// Create link with flex layout
			let a = document.createElement(.a)
			a.className = "search-bar-suggestion-link"
			a.style.display(.flex)
			a.style.alignItems(.center)
			a.style.justifyContent(.spaceBetween)
			a.style.gap(px(12))
			a.style.textDecoration(.none)
			a.style.color(.inherit)
			a.style.width(perc(100))
			a.style.transition(.backgroundColor, s(0.15), .easeInOut)
			a.style.padding(px(4), px(0))

			// Hover effect - dynamic
			a.addEventListener(Event.mouseenter) { _ in
				a.style.backgroundColor(rgba(0, 0, 0, 0.04))
			}
			a.addEventListener(Event.mouseleave) { _ in
				if index != self.activeIndex {
					a.style.backgroundColor(backgroundColorTransparent)
				}
			}

			if index == activeIndex {
				_ = a.classList.add("active")
				a.style.backgroundColor(rgba(0, 0, 0, 0.08))
			}

			let href = "\(resultUrlBase)/\(result.languageCode)/\(result.text)/\(result.homograph)"
			a.href = href

			a.appendChild(textSpan)
			a.appendChild(langSpan)

			// Create list item
			let li = document.createElement(.li)
			li.className = "search-bar-suggestion-item"
			li.style.listStyle(.none)
			li.style.padding(px(8), px(12))

			// Only add border if not the last item
			if index < results.count - 1 {
				li.style.borderBottom(px(1), .solid, rgba(0, 0, 0, 0.08))
			}

			li.appendChild(a)

			searchBarSuggestions.appendChild(li)
		}
	}
}

struct SearchBarSuggestedLemma {
	let id: Int
	let text: String
	let language: String
	let languageCode: String
	let homograph: Int
}

extension SearchBarHydration {
	// Simple JSON parser for search API response
	// Expected format: {"exact": [...], "partial": [...]} 
	private func parseSearchResponse(_ json: CallbackString) -> [SearchBarSuggestedLemma]? {
		// Convert CallbackString to Swift String safely
		var jsonString = ""
		json.withCString { ptr in
			let buffer = UnsafeBufferPointer(start: ptr, count: json.len)
			let bytes = Array(buffer).map { UInt8(bitPattern: $0) }
			jsonString = String(decoding: bytes, as: UTF8.self)
		}
		
		var results: [SearchBarSuggestedLemma] = []
		
		// Helper to extract array content between [ and ]
		func extractArray(from source: String, key: String) -> [String] {
			let searchKey = "\"\(key)\":"

			guard let keyOffset = stringIndexOf(source, searchKey) else { return [] }
			let keyLen = searchKey.utf8.count
			let afterKey = stringSubstring(source, from: keyOffset + keyLen)

			guard let start = stringIndexOfChar(afterKey, CChar(UInt8(ascii: "["))),
				  let end = stringIndexOfChar(afterKey, CChar(UInt8(ascii: "]"))) else { return [] }

			let arrayContent = stringSubstring(afterKey, from: start + 1, to: end)
			if stringTrim(arrayContent).isEmpty { return [] }

			// Split by objects "},"
			return stringSplit(arrayContent, separator: "},\" ").map { obj in
				stringIndexOfChar(obj, CChar(UInt8(ascii: "}"))) != nil ? obj : obj + "}"
			}
		}

		// Helper to extract value for key
		func extractValue(from obj: String, key: String) -> String {
			let searchKey = "\"\(key)\":"

			guard let keyOffset = stringIndexOf(obj, searchKey) else { return "" }
			let keyLen = searchKey.utf8.count
			let afterKey = stringSubstring(obj, from: keyOffset + keyLen)
			let trimmed = stringTrim(afterKey)

			// Check if string
			if stringStartsWith(trimmed, "\"") {
				let afterQuote = stringSubstring(trimmed, from: 1)
				if let endQuote = stringIndexOfChar(afterQuote, CChar(UInt8(ascii: "\""))) {
					return stringSubstring(afterQuote, from: 0, to: endQuote)
				}
			} else {
				// Number or boolean
				var value = ""
				trimmed.withCString { ptr in
					let len = cStringLength(ptr)
					for i in 0..<len {
						let char = ptr[i]
						if char == CChar(UInt8(ascii: ",")) || char == CChar(UInt8(ascii: "}")) || isWhitespace(char) { break }
						value.append(Character(UnicodeScalar(UInt8(bitPattern: char))))
					}
				}
				return value
			}
			return ""
		}
		
		let exactStrs = extractArray(from: jsonString, key: "exact")
		let partialStrs = extractArray(from: jsonString, key: "partial")
		
		for str in exactStrs + partialStrs {
			let text = extractValue(from: str, key: "text")
			let language = extractValue(from: str, key: "language")
			let languageCode = extractValue(from: str, key: "languageCode")
			let homographStr = extractValue(from: str, key: "homograph")
			let homograph = Int(homographStr) ?? 1
			let idStr = extractValue(from: str, key: "id")
			// Handle string ID to Int conversion safely, or default to 0 if alphanumeric
			let id = Int(idStr) ?? 0


			if !text.isEmpty {
				results.append(SearchBarSuggestedLemma(
					id: id,
					text: text,
					language: language,
					languageCode: languageCode,
					homograph: homograph
				))
			}
		}
		
		return results
	}
}

#endif
