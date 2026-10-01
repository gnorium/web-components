#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import Foundation
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  public struct SearchBarView: HTMLContent {
    let inSidebar: Bool
    let openDialog: Bool
    let `class`: String
    let placeholder: String
    let ariaLabel: String
    let searchField: String
    let searchEndpoint: String
    let resultUrlBase: String
    let value: String
    /// Whether typing offers records in a menu under the input. Without
    /// them the bar is a plain field of its form: the button submits it, as
    /// Enter does, and the page may act on what is typed (the records
    /// pages' sidebar filters their table as it is typed).
    let suggestions: Bool

    public init(
      inSidebar: Bool = false,
      openDialog: Bool = false,
      class: String = "",
      placeholder: String = "Search",
      ariaLabel: String = "Search",
      searchField: String = "q",
      searchEndpoint: String = "/api/search",
      resultUrlBase: String = "/results",
      value: String = "",
      suggestions: Bool = true
    ) {
      self.suggestions = suggestions
      self.inSidebar = inSidebar
      self.openDialog = openDialog
      self.class = `class`
      self.placeholder = placeholder
      self.ariaLabel = ariaLabel
      self.searchField = searchField
      self.searchEndpoint = searchEndpoint
      self.resultUrlBase = resultUrlBase
      self.value = value
    }

    /// Binary compatibility for already-compiled callers during incremental builds.
    /// New callers use the initializer above; placement-specific rules belong to
    /// explicit root classes such as `.home`, not an unscoped rule builder.
    @available(*, deprecated, message: "Use an explicit SearchBarView root class instead.")
    public init(
      inSidebar: Bool = false,
      openDialog: Bool = false,
      class: String = "",
      placeholder: String = "Search",
      ariaLabel: String = "Search",
      searchField: String = "q",
      searchEndpoint: String = "/api/search",
      resultUrlBase: String = "/results",
      value: String = "",
      @CSSBuilder style: () -> [CSSOM.CSSRule]
    ) {
      self.init(
        inSidebar: inSidebar,
        openDialog: openDialog,
        class: `class`,
        placeholder: placeholder,
        ariaLabel: ariaLabel,
        searchField: searchField,
        searchEndpoint: searchEndpoint,
        resultUrlBase: resultUrlBase,
        value: value
      )
    }

    public func build() -> DOM.Node {
      // Its suggestions are drawn on the client, each named by a
      // BreadcrumbLabelView: built here so the page links its style sheet.
      if suggestions { _ = BreadcrumbLabelView(context: "", text: "").build() }
      return div {
        // Input - if openDialog is true, make it read-only and use it as a trigger
        input()
          .type(.search)
          .name(searchField)
          .value(value)
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
            selector("&") {
              border(px(1), .solid, borderColorBase)
              color(colorBase)
              fontFamily(typographyFontSans)
              borderRadius(borderRadiusBase)
              padding(px(0), calc(spacing10 + px(32)), px(0), spacing10)
              width(perc(100))
              maxWidth(perc(100))
              height(minSizeInteractiveTouch)
              fontWeight(fontWeightNormal)
              transition(.all, s(0.2), .easeInOut)
              fontSize(fontSizeSmall14)
              boxSizing(.borderBox)
              backgroundColor(backgroundColorBase)
              if openDialog {
                cursor(.pointer)
              }
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
          }

        // Button
        button {
          SearchIconView(size: fontSizeSmall14)
        }
        .type(suggestions ? .button : .submit)
        .class("search-bar-button")
        .ariaLabel("Search")
        .data("search-button", true)
        .style {
          selector("&") {
            position(.absolute)
            insetInlineEnd(0)
            top(perc(50))
            transform(translateY(perc(-50)))
            background(.transparent)
            border(.none)
            color(colorBase)
            marginInlineEnd(spacing10)
            paddingInlineStart(0)
            display(.flex)
            alignItems(.center)
            justifyContent(.center)
            width(px(24))
            height(px(24))
            cursor(.pointer)
            transition(.all, s(0.2), .easeInOut)
          }

          pseudoClass(.hover) {
            transform(translateY(perc(-50)), scale(1.02))
            backgroundColor(.transparent).important()
          }

          pseudoClass(.active) {
            transform(translateY(perc(-50)), scale(0.95))
            outline(.none)
          }

          pseudoClass(.focus) {
            outline(.none)
          }

          media(maxWidth(maxWidthBreakpointPhoneNarrow)) {
            paddingInlineStart(rem(0.5))
          }
        }

        // Dropdown
        if suggestions {
          div {
            ul {
              // Results dynamically inserted by client (WASM hydration)
              // li.search-bar-suggestion-item
              //   a.search-bar-suggestion-link
              //     span.search-bar-suggestion-text (language › title)
              //     span.search-bar-suggestion-detail (voices · type)
              // Styles applied directly via WebAPIs DSL in render() below
            }
            .class("search-bar-suggestions")
            .role(.listbox)
            .style {
              selector("&") {
                listStyle(.none)
                margin(0)
                padding(spacing8, 0)
              }
            }
          }
          .class("search-bar-dropdown")
          .data("search-dropdown", true)
          .data("open", false)
        }
      }
      .class(buildClass())
      .data("search-container", true)
      .data("suggestions", suggestions)
      .style {
        selector("&") {
          display(.flex)
          alignItems(.center)
          position(.relative)
          width(perc(100))
          maxWidth(perc(100))
          height(minSizeInteractiveTouch)
          flex(1)
          boxSizing(.borderBox)
        }
        selector("&.home") {
          // Match the full-width input in SearchMenuView while preserving the
          // same responsive inline padding from ContainerView.
          width(perc(100))
          minWidth(0)
          maxWidth(.none)
          borderRadius(0)
        }
        // Sidebar: base radius, same 14px type + spacing10 padding as main
        selector("&.in-sidebar .search-bar-input") {
          borderRadius(borderRadiusBase)
          height(minSizeInteractiveTouch)
          fontSize(fontSizeSmall14)
          padding(px(0), calc(spacing10 + px(28)), px(0), spacing10)
        }
        selector("&.in-sidebar .search-bar-button") {
          marginInlineEnd(spacing10)
        }
        // Under the input, over what follows, as DropdownView's menu is: in
        // the row beside the input it squeezed the input to a sliver.
        descendant(".search-bar-dropdown") {
          display(.none)
          position(.absolute)
          top(perc(100))
          insetInlineStart(0)
          insetInlineEnd(0)
          marginBlockStart(spacing4)
          maxHeight(px(300))
          overflowY(.auto)
          backgroundColor(backgroundColorBase)
          border(borderWidthBase, .solid, borderColorBase)
          borderRadius(borderRadiusBase)
          boxShadow(boxShadowMedium)
          zIndex(zIndexDropdown)
        }
        descendant(".search-bar-dropdown[data-open='true']") {
          display(.block)
        }
        // Two rows, as every record is offered: its language › its title,
        // then its voices and type.
        descendant(".search-bar-suggestion-link") {
          display(.flex)
          flexDirection(.column)
          alignItems(.flexStart)
          gap(spacing2)
          textDecoration(.none)
          color(.inherit)
          width(perc(100))
          padding(spacing8, spacing12)
          boxSizing(.borderBox)
          transition(.backgroundColor, transitionDurationBase, transitionTimingFunctionSystem)
        }
        // A row is a link, not a dropdown option: no filled highlight.
        // Reached with the arrow keys, it wears LinkView's keyboard focus
        // ring.
        descendant(".search-bar-suggestion-link.active") {
          outline(borderWidthThick, .solid, borderColorBlue)
          outlineOffset(px(-2))
          borderRadius(borderRadiusBase)
        }
        // The name in the link's colors (LinkView's), as the search menu's;
        // its language subtle.
        descendant(".search-bar-suggestion-text") {
          width(perc(100))
          color(colorLink)
          fontSize(fontSizeSmall14)
          fontWeight(fontWeightSemiBold)
          overflowWrap(.breakWord)
        }
        descendant(".search-bar-suggestion-link:hover .search-bar-suggestion-text") { color(colorLinkHover) }
        descendant(".search-bar-suggestion-link:active .search-bar-suggestion-text") { color(colorLinkActive) }
        descendant(".search-bar-suggestion-detail") {
          width(perc(100))
          fontSize(fontSizeXSmall12)
          fontWeight(fontWeightNormal)
          color(colorSubtle)
          overflowWrap(.breakWord)
        }
        descendant(".search-bar-suggestion-item") {
          listStyleType(.none)
        }
        descendant(".search-bar-suggestion-item[data-last='false']") {
          borderBlockEnd(borderWidthBase, .solid, borderColorBase)
        }
      }
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

#if CLIENT
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  public class SearchBarHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: SearchBarHydration?

    public static func hydrateIfPresent() {
      guard document.querySelector(".search-bar-view") != nil else { return }
      let containers = document.querySelectorAll("[data-search-container=\"true\"]")
      for container in containers {
        // A bar without suggestions is its form's field alone.
        if stringEquals(container.getAttribute(data("suggestions")) ?? "", "false") { continue }
        // Local filter bars (e.g. Sessions list) skip remote typeahead.
        var skipRemote = false
        var ancestor: DOM.Element? = container
        while let node = ancestor {
          if stringEquals(node.getAttribute("data-local-filter") ?? "", "true") {
            skipRemote = true
            break
          }
          ancestor = node.parentElement
        }
        if skipRemote { continue }
        instance = SearchBarHydration(container: container)
      }
    }

    private var container: DOM.Element?
    private var input: DOM.Element?
    private var button: DOM.Element?
    private var dropdown: DOM.Element?
    private var searchBarSuggestions: DOM.Element?

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

    public init?(container: DOM.Element? = nil) {
      self.container = container ?? document.querySelector("[data-search-container=\"true\"]")
      guard let container = self.container else { return nil }

      input = container.querySelector("[data-search-input=\"true\"]")
      guard input != nil else { return nil }

      // Read configuration from data attributes
      searchField = input?.dataset["searchField"] ?? "q"
      searchEndpoint = input?.dataset["searchEndpoint"] ?? "/api/search"
      resultUrlBase = input?.dataset["resultUrlBase"] ?? "/results"

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
      let isTrigger = stringEquals(input.dataset.searchTrigger.value ?? "", "true")

      if isTrigger {
        // openDialog mode: clicking opens the search dialog
        _ = input.addEventListener(.click) { [self] (event: Event) in
          self.openSearchDialog()
        }

        _ = button.addEventListener(.click) { [self] (event: Event) in
          self.openSearchDialog()
        }
      } else {
        // Inline search mode: normal search bar functionality
        _ = input.addEventListener(.input) { [self] (event: Event) in
          self.onInput()
        }

        _ = input.addEventListener(.focus) { [self] (event: Event) in
          self.onFocus()
        }

        _ = input.addEventListener(.keydown) { [self] (event: Event) in
          self.onKeyDown(event: event)
        }

        _ = button.addEventListener(.click) { [self] (event: Event) in
          self.onSearch()
        }

        document.addEventListener(.click) { [self] (event: Event) in
          self.isOpen = false
        }
      }
    }

    private func openSearchDialog() {
      // Open the search dialog by dispatching a custom event
      let event = document.createCustomEvent("open-search-dialog", detail: "{}")
      document.dispatchEvent(event)
    }

    private func onInput() {
      if let timerID = debounceTimer {
        window.clearTimeout(timerID)
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

    private func onKeyDown(event: Event) {
      guard isOpen else { return }

      // Compare keys using event.key
      if stringEquals(event.key, "ArrowDown") {
        activeIndex = (activeIndex + 1) % results.count
        render()
        return
      }

      if stringEquals(event.key, "ArrowUp") {
        activeIndex = (activeIndex - 1 + results.count) % results.count
        render()
        return
      }

      if stringEquals(event.key, "Enter") {
        onSearch()
        return
      }

      if stringEquals(event.key, "Escape") {
        isOpen = false
        render()
        return
      }
    }

    private func cStringEquals(
      _ ptr1: UnsafePointer<CChar>, _ ptr2: UnsafePointer<CChar>, _ length: Int
    ) -> Bool {
      for i in 0..<length {
        if ptr1[i] != ptr2[i] { return false }
      }
      return ptr1[length] == 0
    }

    private func onSearch() {
      if activeIndex >= 0 && activeIndex < results.count {
        location.href = href(of: results[activeIndex])
        return
      }
      let q = (input as? HTML.HTMLInputElement)?.value ?? ""
      if q.isEmpty {
        location.href = resultUrlBase
      } else {
        location.href = "\(resultUrlBase)?\(searchField)=\(q)"
      }
    }

    private func fetchResults() {
      guard let input else { return }
      let query = (input as? HTML.HTMLInputElement)?.value ?? ""
      guard !query.isEmpty else {
        results = []
        isOpen = false
        render()
        return
      }
      self.query = query

      let url = "\(searchEndpoint)?\(searchField)=\(query)"

      input.fetch(url) { [self] (jsonString: String?) in
        guard let json = jsonString else {
          console.error("SearchBar fetch failed")
          self.results = []
          self.isOpen = false
          return
        }

        // Parse JSONFormattable response manually
        if let parsed = self.parseSearchResponse(json) {
          if parsed.isEmpty { console.log("SearchBar 0 results for \(query)") }
          self.results = parsed
          self.isOpen = !parsed.isEmpty
          self.activeIndex = -1
          // Drawn now: the answer was only kept, and shown at the next key
          // press or focus.
          self.render()
        } else {
          console.error("SearchBar: Failed to parse JSONFormattable")
          self.results = []
          self.isOpen = false
        }
      }
    }

    private func render() {
      guard let dropdown else { return }
      guard let searchBarSuggestions = searchBarSuggestions else { return }

      dropdown.setAttribute(data("open"), isOpen)
      searchBarSuggestions.innerHTML = ""

      for (index, result) in results.enumerated() {
        // Its language › its title, as a breadcrumb, as
        // SearchMenuView and DropdownView's record options draw it.
        let textSpan = document.createElement(.span)
        textSpan.className = "search-bar-suggestion-text"
        textSpan.innerHTML = BreadcrumbLabelView(
          context: stringIsEmpty(result.language) ? "—" : result.language, text: result.text
        ).render()

        // A work's voices ("—" when unknown) and its type ("—" when
        // unknown); a word has no voices part.
        let detailSpan = document.createElement(.span)
        detailSpan.className = "search-bar-suggestion-detail"
        var parts: [String] = []
        if !stringIsEmpty(result.voices) { parts.append(result.voices) }
        parts.append(stringIsEmpty(result.type) ? "—" : result.type)
        detailSpan.textContent = stringJoin(parts, separator: " · ")

        // Create link with flex layout
        let a = document.createElement(.a)
        a.className = "search-bar-suggestion-link"

        if index == activeIndex {
          _ = a.classList.add("active")
        }

        a.href = href(of: result)

        a.appendChild(textSpan)
        a.appendChild(detailSpan)

        // Create list item
        let li = document.createElement(.li)
        li.className = "search-bar-suggestion-item"
        li.setAttribute(data("last"), index == results.count - 1)

        li.appendChild(a)

        searchBarSuggestions.appendChild(li)
      }
    }

    /// Where a suggestion leads: the record's own path, as the answer gives
    /// it (JSON writes its slashes "\/"), else one made of its segments.
    private func href(of result: SearchBarSuggestedLemma) -> String {
      if !stringIsEmpty(result.url) { return stringReplace(result.url, "\\/", "/") }
      let base = stripQuery(resultUrlBase)
      return "\(base)/\(result.languageCode)/\(result.text)/\(result.homograph)"
    }

    private func stripQuery(_ url: String) -> String {
      let parts = stringSplit(url, separator: "?")
      return parts.count > 0 ? parts[0] : url
    }
  }

  struct SearchBarSuggestedLemma {
    let id: Int
    let text: String
    let language: String
    let languageCode: String
    /// Its voices as text: authors and translators, or etymons.
    let voices: String
    /// Its type (Book, Noun…); "" when it has none.
    let type: String
    let homograph: Int
    let url: String
  }

  extension SearchBarHydration {
    // Simple JSONFormattable parser for search API response
    // Expected format: {"exact": [...], "partial": [...]}
    private func parseSearchResponse(_ json: String) -> [SearchBarSuggestedLemma]? {
      let jsonString = json

      var results: [SearchBarSuggestedLemma] = []

      // Helper to extract array content between [ and ]
      func extractArray(from source: String, key: String) -> [String] {
        let searchKey = "\"\(key)\":"

        guard let keyOffset = stringIndexOf(source, searchKey) else { return [] }
        let keyLen = searchKey.utf8.count
        let afterKey = stringSubstring(source, from: keyOffset + keyLen)

        guard let start = stringIndexOfChar(afterKey, CChar(UInt8(ascii: "["))),
          let end = stringIndexOfChar(afterKey, CChar(UInt8(ascii: "]")))
        else { return [] }

        let arrayContent = stringSubstring(afterKey, from: start + 1, to: end)
        if stringTrim(arrayContent).isEmpty { return [] }

        // Each object whole: a split on a separator no compact JSON holds
        // left the array one object, so only its first record was offered.
        return searchResultObjects(in: arrayContent)
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
          var valueBytes: [UInt8] = []
          trimmed.withCString { ptr in
            let len = cStringLength(ptr)
            for i in 0..<len {
              let char = ptr[i]
              if char == CChar(UInt8(ascii: ",")) || char == CChar(UInt8(ascii: "}"))
                || isWhitespace(char)
              {
                break
              }
              valueBytes.append(UInt8(bitPattern: char))
            }
          }
          return String(decoding: valueBytes, as: UTF8.self)
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
        let homograph = parseInt(homographStr) ?? 1
        let idStr = extractValue(from: str, key: "id")
        // Handle string ID to Int conversion safely, or default to 0 if alphanumeric
        let id = parseInt(idStr) ?? 0

        if !text.isEmpty {
          results.append(
            SearchBarSuggestedLemma(
              id: id,
              text: text,
              language: language,
              languageCode: languageCode,
              voices: extractValue(from: str, key: "qualifier"),
              type: extractValue(from: str, key: "type"),
              homograph: homograph,
              url: extractValue(from: str, key: "url")
            ))
        }
      }

      return results
    }
  }
#endif
