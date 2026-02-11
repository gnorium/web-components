#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct SearchMenuView: HTMLProtocol {
	let id: String
	let placeholder: String
	let results: [SearchResult]?
	let `class`: String
	let searchField: String
	let searchEndpoint: String
	let resultUrlBase: String

	public struct SearchResult: Sendable {
		let id: String
		let term: String
		let matchedSegments: [MatchedSegment]
		let metadata: String?

		public struct MatchedSegment: Sendable {
			let text: String
			let isMatch: Bool

			public init(text: String, isMatch: Bool) {
				self.text = text
				self.isMatch = isMatch
			}
		}

		public init(id: String, term: String, matchedSegments: [MatchedSegment], metadata: String? = nil) {
			self.id = id
			self.term = term
			self.matchedSegments = matchedSegments
			self.metadata = metadata
		}
	}

	public init(
		id: String = "search-menu",
		placeholder: String = "Search lemma",
		results: [SearchResult]? = nil,
		class: String = "",
		searchField: String = "q",
		searchEndpoint: String = "/api/search",
		resultUrlBase: String = "/results"
	) {
		self.id = id
		self.placeholder = placeholder
		self.results = results
		self.`class` = `class`
		self.searchField = searchField
		self.searchEndpoint = searchEndpoint
		self.resultUrlBase = resultUrlBase
	}

	public func render(indent: Int = 0) -> String {
		// Full-screen search menu - iOS-style
		div {
			// Backdrop with blur effect
			div {}
            .class("search-menu-backdrop")
            .data("search-menu-backdrop", "true")
            .style {
                searchMenuBackdropCSS()
            }

			// Search menu container - full screen
			div {
				ContainerView(size: .xLarge) {
					div {
						// Search input at top
						TypeaheadSearchView(
							id: id,
							formAction: resultUrlBase,
							highlightQuery: true,
							showThumbnail: false,
							autoExpandWidth: false,
							showEmptyQueryResults: true,
							placeholder: placeholder,
							class: "search-menu-typeahead"
						)

						// Footer with keyboard hints
						div {
							div {
								// Navigation
								div {
									kbd { "↑" }
                                    .class("keyboard-hint-key")
                                    .style { keyboardHintKeyCSS() }
									kbd { "↓" }
                                    .class("keyboard-hint-key")
                                    .style { keyboardHintKeyCSS() }
									span { "to navigate" }
                                    .class("keyboard-hint-label")
                                    .style { keyboardHintLabelCSS() }
								}
								.class("keyboard-hint-group")
								.style { keyboardHintGroupCSS() }

								// Selection
								div {
									kbd { "↵" }
                                    .class("keyboard-hint-key")
                                    .style { keyboardHintKeyCSS() }
									span { "to select" }
                                    .class("keyboard-hint-label")
                                    .style { keyboardHintLabelCSS() }
								}
								.class("keyboard-hint-group")
								.style { keyboardHintGroupCSS() }

								// Close
								div {
									kbd { "esc" }
                                    .class("keyboard-hint-key")
                                    .style { keyboardHintKeyCSS() }
									span { "to close" }
                                    .class("keyboard-hint-label")
                                    .style { keyboardHintLabelCSS() }
								}
								.class("keyboard-hint-group")
								.style { keyboardHintGroupCSS() }
							}
							.class("keyboard-hint-container")
							.style { keyboardHintContainerCSS() }
						}
						.class("search-menu-footer")
						.style { searchMenuFooterCSS() }
					}
					.style {
						display(.flex)
						flexDirection(.column)
						gap(spacing16)
					}
				}
			}
			.class("search-menu-container")
			.data("search-menu-container", "true")
			.data("search-field", searchField)
			.data("search-endpoint", searchEndpoint)
			.data("result-url-base", resultUrlBase)
			.style {
				searchMenuContainerCSS()
			}
		}
		.class(`class`.isEmpty ? "search-menu-view" : "search-menu-view \(`class`)")
		.data("search-menu", "true")
		.style {
			searchMenuViewCSS()
		}
		.render(indent: indent)
	}

	@CSSBuilder
	private func searchMenuViewCSS() -> [CSSProtocol] {
		// Hidden by default, positioned right below navbar
		display(.none)
		position(.fixed)
		top(px(96))  // Right below navbar
		insetInlineStart(0)
		width(perc(100))
		zIndex(zIndexBase)
		pointerEvents(.none)
	}

	@CSSBuilder
	private func searchMenuBackdropCSS() -> [CSSProtocol] {
		position(.fixed)
		top(px(96))  // Start below navbar (navbar height is 96px)
		insetInlineStart(0)
		width(perc(100))
		height(calc(vh(100) - px(96)))  // Full height minus navbar
		backgroundColor(rgba(0, 0, 0, 0.4))
		backdropFilter("blur(20px)")
		customProperty("-webkit-backdrop-filter", "blur(20px)")
		opacity(0)
		transition(.opacity, transitionDurationMedium, transitionTimingFunctionSystem)
		zIndex(-1)
	}

	@CSSBuilder
	private func searchMenuContainerCSS() -> [CSSProtocol] {
		position(.relative)
		width(perc(100))
		backgroundColor(backgroundColorBase)
		paddingBlockStart(spacing16)
		paddingBlockEnd(spacing16)
		borderBlockEnd(borderWidthBase, .solid, borderColorBase)

		// Start hidden - collapsed at navbar level with slide down animation
		maxHeight(px(0))
		overflow(.hidden)
		transform(translateY(px(-125)))
		transition(
			(.maxHeight, transitionDurationMedium, transitionTimingFunctionSystem),
			(.opacity, transitionDurationMedium, transitionTimingFunctionSystem),
			(.transform, transitionDurationMedium, transitionTimingFunctionSystem)
		)
		opacity(0)

		// Desktop: more vertical padding
		media(minWidth(minWidthBreakpointTablet)) {
			paddingBlockStart(spacing20)
			paddingBlockEnd(spacing20)
		}
	}

	@CSSBuilder
	private func searchMenuFooterCSS() -> [CSSProtocol] {
		// Hide keyboard hints on mobile
		display(.none)
		alignItems(.center)
		justifyContent(.flexStart)
		padding(0)
		marginBlockStart(spacing16)

		// Show only on desktop
		media(minWidth(minWidthBreakpointTablet)) {
			display(.flex)
		}
	}

	@CSSBuilder
	private func keyboardHintContainerCSS() -> [CSSProtocol] {
		display(.flex)
		gap(spacing16)
		alignItems(.center)
		flexWrap(.wrap)
	}

	@CSSBuilder
	private func keyboardHintGroupCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		gap(spacing6)
	}

	@CSSBuilder
	private func keyboardHintKeyCSS() -> [CSSProtocol] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		minWidth(px(20))
		height(px(20))
		padding(0, spacing8)
		fontFamily(typographyFontMono)
		fontSize(fontSizeXSmall12)
		fontWeight(fontWeightSemiBold)
		color(colorBase)
		backgroundColor(backgroundColorNeutralSubtle)
		border(borderWidthBase, .solid, borderColorSubtle)
		borderRadius(borderRadiusMinimal)
		boxShadow(px(0), px(1), px(1), px(0), rgba(0, 0, 0, 0.05))
		lineHeight(1)
	}

	@CSSBuilder
	private func keyboardHintLabelCSS() -> [CSSProtocol] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeXSmall12)
		color(colorSubtle)
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

public class SearchMenuHydration: @unchecked Sendable {
	private var searchField: String = ""
	private var searchEndpoint: String = ""
	private var resultUrlBase: String = ""
	private var isMenuOpen: Bool = false

	public init() {}

	public func hydrate() {
		// Listen for all search trigger clicks (desktop and mobile)
		let searchTriggers = document.querySelectorAll("[data-search-trigger=\"true\"]")
		for searchTrigger in searchTriggers {
			_ = searchTrigger.addEventListener(.click) { [self] event in
				event.preventDefault()
				self.toggleMenu()
			}
		}

		// Listen for ESC key to close menu
		document.addEventListener(.keydown) { [self] event in
			let key = event.key
			if stringEquals(key, "Escape") || stringEquals(key, "Esc") {
				self.closeMenu()
			}
		}

		// Close menu when clicking backdrop
		if let backdrop = document.querySelector("[data-search-menu-backdrop=\"true\"]") {
			_ = backdrop.addEventListener(.click) { [self] _ in
				self.closeMenu()
			}
		}

		// Hydrate search functionality
		let typeaheadElements = document.querySelectorAll(".search-menu-typeahead")
		for typeahead in typeaheadElements {
			hydrateTypeahead(typeahead)
		}
	}

	private func hydrateTypeahead(_ typeahead: Element) {
		// Read configuration from data attributes on the search menu container
		guard let container = document.querySelector("[data-search-menu-container=\"true\"]") else {
			return
		}
		searchField = container.dataset["searchField"] ?? "q"
		searchEndpoint = container.dataset["searchEndpoint"] ?? "/api/search"
		resultUrlBase = container.dataset["resultUrlBase"] ?? "/results"

		// Ensure input exists but we don't need the reference
		guard typeahead.querySelector("input") != nil else {
			return
		}

		// Listen for custom 'input' event from TypeaheadSearchInstance
		typeahead.addEventListener("input") { [self] event in
			// event.detail is JSONProtocol-stringified, so we need to parse it
			var rawDetail = event.detail

			// Strip quotes if JSONProtocol-stringified (e.g., "\"hello\"" -> "hello")
			let detailBytes = Array(rawDetail.utf8)
			if detailBytes.count >= 2, detailBytes.first == 34, detailBytes.last == 34 {
				let innerBytes = detailBytes[1..<detailBytes.count-1]
				rawDetail = String(decoding: innerBytes, as: UTF8.self)
			}

			let query = rawDetail

			// Ignore single character "0" which appears to be a spurious event
			// from the disabled state changes in SearchInputInstance
			if stringEquals(query, "0") {
				return
			}

			guard !query.isEmpty else {
				return
			}

			self.performSearch(query: query, typeahead: typeahead)
		}

		typeahead.addEventListener("search-result-click") { [self] event in
			let value = event.detail
            _ = value // Suppress unused warning if logic is pending

            // Close the search menu when a result is clicked
            self.closeMenu()
		}

		typeahead.addEventListener("submit") { [self] event in
			let query = event.detail
			guard !query.isEmpty else { return }
			window.location.href = "\(resultUrlBase)?value=\(query)&field=\(searchField)"
		}
	}

	private struct SuggestedLemma: Sendable {
		let id: Int
		let lemma: String
		let language: String
		let languageCode: String
		let homograph: Int
	}

	private func performSearch(query: String, typeahead: Element) {
        // Strip surrounding quotes if present (likely due to event serialization)
        // Use UTF8 bytes to detect quotes (34) to avoid Grapheme breaking dependency
        var cleanQuery = query
        let queryBytes = Array(query.utf8)
        if queryBytes.count >= 2, queryBytes.first == 34, queryBytes.last == 34 {
            let innerBytes = queryBytes[1..<queryBytes.count-1]
            cleanQuery = String(decoding: innerBytes, as: UTF8.self)
        }
        
        // Encode query to be URL safe
        let encodedQuery = encodeURIComponent(cleanQuery)
        
        // Remove trailing slash to prevent redirect stripping params
        let url = "\(searchEndpoint)?value=\(encodedQuery)&field=\(searchField)"
        
        console.log("Performing search: \(url)") // Debug log
        
        typeahead.fetch(url) { [self] jsonString in
            guard let json = jsonString else {
                console.log("SearchDialogView: No JSONProtocol response received")
                return
            }

            console.log("SearchDialogView: Received JSONProtocol response")

            // Parse JSONProtocol results
            if let results = self.parseSearchResponse(json) {
                console.log("SearchDialogView: Parsed \(results.count) results")
                // Update Typeahead menu
                self.updateTypeaheadMenu(typeahead: typeahead, results: results)
            } else {
                console.log("SearchDialogView: Failed to parse search response")
            }
        }
	}
    
    private func encodeURIComponent(_ string: String) -> String {
        var bytes: [UInt8] = []
        for byte in Array(string.utf8) {
            // RFC 3986 unreserved characters: A-Z, a-z, 0-9, -, _, ., ~
            if (byte >= 65 && byte <= 90) || // A-Z
               (byte >= 97 && byte <= 122) || // a-z
               (byte >= 48 && byte <= 57) || // 0-9
               byte == 45 || byte == 95 || byte == 46 || byte == 126 { // - _ . ~
                bytes.append(byte)
            } else {
                bytes.append(37) // %
                // Convert byte to hex manually to avoid String overhead
                let upper = (byte >> 4) & 0xF
                let lower = byte & 0xF
                
                func hexChar(_ v: UInt8) -> UInt8 {
                    return v < 10 ? 48 + v : 65 + (v - 10)
                }
                
                bytes.append(hexChar(upper))
                bytes.append(hexChar(lower))
            }
        }
        return String(decoding: bytes, as: UTF8.self)
    }
    
    private func updateTypeaheadMenu(typeahead: Element, results: [SuggestedLemma]) {
        guard let menu = typeahead.querySelector(".typeahead-search-menu") else {
            console.log("SearchDialogView: Menu element not found")
            return
        }

        console.log("SearchDialogView: Updating menu with \(results.count) items")

        // Clear existing
        menu.innerHTML = ""

        // Create new menu items using DOM API
        for result in results {
            let item = document.createElement(.div)
            item.className = "menu-item-view"
            item.setAttribute(data("value"), result.lemma)
            item.setAttribute(.role, .option)
            item.setAttribute(.tabindex, -1)

            // Apply menu item styles
            item.style.display(.flex)
            item.style.alignItems(.center)
            item.style.gap(spacing12)
            item.style.padding(spacing8, spacing12)
            item.style.minHeight(minSizeInteractivePointer)
            item.style.fontFamily(typographyFontSans)
            item.style.fontSize(fontSizeMedium16)
            item.style.lineHeight(lineHeightSmall22)
            item.style.color(colorSubtle)
            item.style.backgroundColor(backgroundColorTransparent)
            item.style.border(borderWidthBase, .solid, borderColorSubtle)
            item.style.borderRadius(borderRadiusBase)
            item.style.cursor(cursorBase)
            item.style.userSelect(.none)
            item.style.textDecoration(textDecorationNone)
            item.style.boxSizing(.borderBox)
            item.style.transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
			 
            // Construct URL for navigation
            let href = "\(resultUrlBase)/\(result.languageCode)/\(result.lemma)/\(result.homograph)"
            item.setAttribute(data("url"), href)
            
            // Text Content Wrapper
            let textContent = document.createElement(.span)
            textContent.className = "menu-item-text"
            textContent.style.display(.flex)
            textContent.style.flexDirection(.column)
            textContent.style.gap(spacing4)
            textContent.style.minWidth(px(0))
            textContent.style.flex(1)

            // Title Wrapper
            let titleWrapper = document.createElement(.span)
            titleWrapper.className = "menu-item-title"
            titleWrapper.style.display(.flex)
            titleWrapper.style.alignItems(.center)
            titleWrapper.style.gap(spacing4)

            let label = document.createElement(.span)
            label.className = "menu-item-label"
            label.textContent = result.lemma
            label.style.fontFamily(typographyFontSans)
            label.style.fontSize(fontSizeMedium16)
            label.style.fontWeight(fontWeightNormal)
            label.style.lineHeight(lineHeightSmall22)
            label.style.color(colorBase)

            titleWrapper.appendChild(label)
            
            textContent.appendChild(titleWrapper)
            
            // Description
            let description = document.createElement(.span)
            description.className = "menu-item-description"
            description.textContent = result.language
            description.style.fontFamily(typographyFontSans)
            description.style.fontSize(fontSizeSmall14)
            description.style.fontWeight(fontWeightNormal)
            description.style.lineHeight(lineHeightSmall22)
            description.style.color(colorSubtle)

            textContent.appendChild(description)
            item.appendChild(textContent)

            // Add hover/active/focus event listeners for progressive styling
            _ = item.addEventListener(.mouseenter) { _ in
                item.style.color(colorBlue)
                item.style.border(borderWidthBase, .solid, borderColorBlue)
				item.style.cursor(cursorBaseHover)
            }

            _ = item.addEventListener(.mouseleave) { _ in
                item.style.color(colorSubtle)
                item.style.border(borderWidthBase, .solid, borderColorSubtle)
				item.style.cursor(cursorBase)
            }

            _ = item.addEventListener(.mousedown) { _ in
                item.style.color(colorBlue)
                item.style.border(borderWidthBase, .solid, borderColorBlue)
				item.style.cursor(cursorBaseHover)
            }

            _ = item.addEventListener(.mouseup) { _ in
                item.style.color(colorBlue)
                item.style.border(borderWidthBase, .solid, borderColorBlue)
				item.style.cursor(cursorBaseHover)
            }

            _ = item.addEventListener(.focus) { _ in
                item.style.color(colorBlueFocus)
                item.style.outline(borderWidthBase, .solid, borderColorBlueFocus)
                item.style.outlineOffset(px(-1))
            }

            _ = item.addEventListener(.blur) { _ in
                item.style.color(colorSubtle)
                item.style.outline(.none)
            }

            menu.appendChild(item)
        }

        console.log("SearchDialogView: Menu items appended, dispatching update event")

        // Dispatch event for TypeaheadSearchInstance to re-scan menu items
        typeahead.dispatchEvent(CustomEvent(type: "typeahead-menu-updated", detail: "{}"))

        console.log("SearchDialogView: Menu update complete")
    }
    
    private func parseSearchResponse(_ json: CallbackString) -> [SuggestedLemma]? {
        let jsonString = json.toString()
        
        // Manual JSONProtocol Parsing to avoid Foundation dependency in Wasm
        var results: [SuggestedLemma] = []
        
        // Helper to extract JSONProtocol array
        func extractArray(from source: String, key: String) -> [String] {
            let searchKey = "\"\(key)\":"
            guard let keyOffset = stringIndexOf(source, searchKey) else { return [] }
            let keyLen = cStringLength(searchKey)
            let afterKey = stringSubstring(source, from: keyOffset + keyLen)

            guard let start = stringIndexOfChar(afterKey, CChar(UInt8(ascii: "["))),
                  let end = stringIndexOfChar(afterKey, CChar(UInt8(ascii: "]"))) else { return [] }

            let arrayContent = stringSubstring(afterKey, from: start + 1, to: end)
            if stringTrim(arrayContent).isEmpty { return [] }

            // Split by object close brace with comma (},{)
            var objects: [String] = []
            var braceDepth = 0
            var objStart = 0

            let bytes = Array(arrayContent.utf8)
            var i = 0
            while i < bytes.count {
                let char = bytes[i]
                if char == 123 { // '{'
                    if braceDepth == 0 {
                        objStart = i
                    }
                    braceDepth += 1
                } else if char == 125 { // '}'
                    braceDepth -= 1
                    if braceDepth == 0 {
                        let objLen = i - objStart + 1
                        let buffer = Array(bytes[objStart..<(objStart + objLen)])
                        let obj = String(decoding: buffer, as: UTF8.self)
                        objects.append(obj)
                    }
                }
                i += 1
            }

            return objects
        }

        func extractValue(from obj: String, key: String) -> String {
            let searchKey = "\"\(key)\":"

            guard let keyOffset = stringIndexOf(obj, searchKey) else { return "" }
            let keyLen = cStringLength(searchKey)
            let afterKey = stringSubstring(obj, from: keyOffset + keyLen)
            let trimmed = stringTrim(afterKey)

            if stringStartsWith(trimmed, "\"") {
                let afterQuote = stringSubstring(trimmed, from: 1)
                if let endQuote = stringIndexOfChar(afterQuote, CChar(UInt8(ascii: "\""))) {
                    return stringSubstring(afterQuote, from: 0, to: endQuote)
                }
            } else {
                var valueBytes: [UInt8] = []
                let bytes = Array(trimmed.utf8)
                for i in 0..<bytes.count {
                    let char = bytes[i]
                    if char == UInt8(ascii: ",") || char == UInt8(ascii: "}") || isWhitespace(CChar(bitPattern: char)) { break }
                    valueBytes.append(char)
                }
                return String(decoding: valueBytes, as: UTF8.self)
            }
            return ""
        }
        
        let exactStrs = extractArray(from: jsonString, key: "exact")
        let partialStrs = extractArray(from: jsonString, key: "partial")
        
        for str in exactStrs + partialStrs {
            let lemma = extractValue(from: str, key: "lemma")
            let language = extractValue(from: str, key: "language")
            let languageCode = extractValue(from: str, key: "languageCode")
            let homographStr = extractValue(from: str, key: "homograph")
            let homograph = Int(homographStr) ?? 1
            let idStr = extractValue(from: str, key: "id")
            let id = Int(idStr) ?? 0

            if !lemma.isEmpty {
                results.append(SuggestedLemma(
                    id: id,
                    lemma: lemma,
                    language: language,
                    languageCode: languageCode,
                    homograph: homograph
                ))
            }
        }
        
        return results
    }

	private func toggleMenu() {
		if isMenuOpen {
			closeMenu()
		} else {
			openMenu()
		}
	}

	private func openMenu() {
		// First scroll to top so navbar is fully visible
		window.scrollTo(0, 0, behavior: .smooth)

		isMenuOpen = true

		if let menu = document.querySelector("[data-search-menu=\"true\"]") {
			// Show menu
			menu.style.display(.block)
			menu.style.pointerEvents(.auto)

			// Use requestAnimationFrame to ensure initial state is rendered before animating
			window.requestAnimationFrame {
				// Animate backdrop
				if let backdrop = menu.querySelector("[data-search-menu-backdrop=\"true\"]") {
					backdrop.style.opacity(1)
					backdrop.style.pointerEvents(.auto)
				}

				// Animate container (expand height, fade in, and slide down)
				if let container = menu.querySelector("[data-search-menu-container=\"true\"]") {
					// Set max-height to viewport height minus navbar to show full content
					container.style.maxHeight(calc(vh(100) - px(96)))
					container.style.overflow(.visible)
					container.style.opacity(1)
					container.style.transform(translateY(px(0)))
				}

				// Show keyboard hints footer on desktop
				if let footer = menu.querySelector(".search-menu-footer") {
					footer.style.display(.flex)
				}
			}

			// Prevent body scroll
			document.body.style.overflow(.hidden)

			// Focus the search input after animation starts
			window.setTimeout(100) {
				if let input = menu.querySelector("input") {
					input.focus()
				}
			}
		}
	}

	private func closeMenu() {
		isMenuOpen = false

		if let menu = document.querySelector("[data-search-menu=\"true\"]") {
			// Animate out backdrop
			if let backdrop = menu.querySelector("[data-search-menu-backdrop=\"true\"]") {
				backdrop.style.opacity(0)
				backdrop.style.pointerEvents(.none)
			}

			// Hide keyboard hints footer
			if let footer = menu.querySelector(".search-menu-footer") {
				footer.style.display(.none)
			}

			// Animate out container (collapse height, fade out, and slide up)
			if let container = menu.querySelector("[data-search-menu-container=\"true\"]") {
				container.style.maxHeight(px(0))
				container.style.overflow(.hidden)
				container.style.opacity(0)
				container.style.transform(translateY(px(-125)))
			}

			// Hide menu after animation completes (250ms)
			window.setTimeout(250) {
				menu.style.display(.none)
				menu.style.pointerEvents(.none)
			}

			// Re-enable body scroll
			document.body.style.overflow(.auto)

			// Clear search input
			if let input = menu.querySelector("input") {
				input.value = ""
				input.blur()
			}

			// Clear any search results
			if let resultsMenu = menu.querySelector(".typeahead-search-menu") {
				resultsMenu.innerHTML = ""
			}
		}
	}
}

#endif
