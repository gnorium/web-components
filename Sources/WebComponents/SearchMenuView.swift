#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct SearchMenuView: HTMLContent {
    let id: String
    let placeholder: String
    let results: [SearchResult]?
    let `class`: String
    let searchField: String
    let searchEndpoint: String
    let resultUrlBase: String
    let resultTitleKey: String
    let resultSubtitleKey: String
    let resultUrlKey: String

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

      public init(
        id: String, term: String, matchedSegments: [MatchedSegment], metadata: String? = nil
      ) {
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
      resultUrlBase: String = "/results",
      resultTitleKey: String = "title",
      resultSubtitleKey: String = "subtitle",
      resultUrlKey: String = "url"
    ) {
      self.id = id
      self.placeholder = placeholder
      self.results = results
      self.`class` = `class`
      self.searchField = searchField
      self.searchEndpoint = searchEndpoint
      self.resultUrlBase = resultUrlBase
      self.resultTitleKey = resultTitleKey
      self.resultSubtitleKey = resultSubtitleKey
      self.resultUrlKey = resultUrlKey
    }

    public func render() -> Node {
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
              gap(spacing8)
            }
          }
        }
        .class("search-menu-container")
        .data("search-menu-container", "true")
        .data("search-field", searchField)
        .data("search-endpoint", searchEndpoint)
        .data("result-url-base", resultUrlBase)
        .data("result-title-key", resultTitleKey)
        .data("result-subtitle-key", resultSubtitleKey)
        .data("result-url-key", resultUrlKey)
        .style {
          searchMenuContainerCSS()
        }
      }
      .class(`class`.isEmpty ? "search-menu-view" : "search-menu-view \(`class`)")
      .data("search-menu", "true")
      .style {
        searchMenuViewCSS()
      }
    }

    @CSSBuilder
    private func searchMenuViewCSS() -> [CSSRule] {
      // Hidden by default, positioned right below navbar
      display(.none)
      position(.fixed)
      top(px(96))
      insetInlineStart(0)
      width(perc(100))
      zIndex(zIndexOverlay)
      pointerEvents(.none)
    }

    @CSSBuilder
    private func searchMenuBackdropCSS() -> [CSSRule] {
      position(.fixed)
      top(px(96))  // Start below navbar (navbar height is 96px)
      insetInlineStart(0)
      width(perc(100))
      height(calc(vh(100) - px(96)))  // Full height minus navbar
      backgroundColor(rgba(0, 0, 0, 0.4))
      backdropFilter(blur(rem(1)))
      webkitBackdropFilter(blur(rem(1)))
      opacity(0)
      transition(.opacity, transitionDurationMedium, transitionTimingFunctionSystem)
      zIndex(-1)
    }

    @CSSBuilder
    private func searchMenuContainerCSS() -> [CSSRule] {
      position(.relative)
      width(perc(100))
      backgroundColor(backgroundColorBase)
      paddingBlockStart(spacing16)
      paddingBlockEnd(spacing16)
      borderBlockEnd(borderWidthBase, .solid, borderColorBase)

      // Start hidden — translated fully above; slides down from beneath navbar
      opacity(0)
      transform(translateY(perc(-100)))
      transition(
        (.opacity, transitionDurationMedium, transitionTimingFunctionSystem),
        (.transform, transitionDurationMedium, transitionTimingFunctionSystem)
      )

      // Desktop: more vertical padding
      media(minWidth(minWidthBreakpointTablet)) {
        paddingBlockStart(spacing20)
        paddingBlockEnd(spacing20)
      }
    }

    @CSSBuilder
    private func searchMenuFooterCSS() -> [CSSRule] {
      // Hide keyboard hints on mobile
      display(.none)
      alignItems(.center)
      justifyContent(.flexStart)
      padding(0)

      // Show only on desktop
      media(minWidth(minWidthBreakpointTablet)) {
        display(.flex)
      }
    }

    @CSSBuilder
    private func keyboardHintContainerCSS() -> [CSSRule] {
      display(.flex)
      gap(spacing16)
      alignItems(.center)
      flexWrap(.wrap)
    }

    @CSSBuilder
    private func keyboardHintGroupCSS() -> [CSSRule] {
      display(.flex)
      alignItems(.center)
      gap(spacing6)
    }

    @CSSBuilder
    private func keyboardHintKeyCSS() -> [CSSRule] {
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
    private func keyboardHintLabelCSS() -> [CSSRule] {
      fontFamily(typographyFontSans)
      fontSize(fontSizeXSmall12)
      color(colorSubtle)
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

  public class SearchMenuHydration: @unchecked Sendable {
    private var searchField: String = ""
    private var searchEndpoint: String = ""
    private var resultUrlBase: String = ""
    private var resultTitleKey: String = "title"
    private var resultSubtitleKey: String = "subtitle"
    private var resultUrlKey: String = "url"
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

      document.addEventListener(.keydown) { [self] event in
        let key = event.key
        
        // Open menu with '/' shortcut
        if stringEquals(key, "/") && !self.isMenuOpen {
          // Check if user is not already in an input/textarea
          let activeElement = document.activeElement
          let tagName = activeElement?.tagName ?? ""
          
          if !stringEquals(tagName, "INPUT") && !stringEquals(tagName, "TEXTAREA") {
            event.preventDefault()
            self.openMenu()
          }
        }

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

      // Close search when ellipsis menu opens (event from NavbarHydration)
      _ = document.addEventListener("ellipsis-menu-opened") { [self] _ in
        if self.isMenuOpen { self.closeMenu() }
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
      searchField = container.dataset["searchField"] ?? ""
      if stringEquals(searchField, "") { searchField = "q" }

      searchEndpoint = container.dataset["searchEndpoint"] ?? ""
      if stringEquals(searchEndpoint, "") { searchEndpoint = "/api/search" }

      resultUrlBase = container.dataset["resultUrlBase"] ?? ""
      if stringEquals(resultUrlBase, "") { resultUrlBase = "/results" }

      resultTitleKey = container.dataset["resultTitleKey"] ?? "title"
      resultSubtitleKey = container.dataset["resultSubtitleKey"] ?? "subtitle"
      resultUrlKey = container.dataset["resultUrlKey"] ?? "url"

      // Ensure input exists but we don't need the reference
      guard typeahead.querySelector("input") != nil else {
        return
      }

      // Listen for custom 'input' event from TypeaheadSearchInstance
      typeahead.addEventListener("input") { [self] event in
        // event.detail is JSONFormattable-stringified, so we need to parse it
        var rawDetail = event.detail

        // Strip quotes if JSONFormattable-stringified (e.g., "\"hello\"" -> "hello")
        let detailBytes = Array(rawDetail.utf8)
        if detailBytes.count >= 2, detailBytes.first == 34, detailBytes.last == 34 {
          let innerBytes = detailBytes[1..<detailBytes.count - 1]
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
        _ = value  // Suppress unused warning if logic is pending

        // Close the search menu when a result is clicked
        self.closeMenu()
      }

      typeahead.addEventListener("submit") { [self] event in
        var rawDetail = event.detail

        // Strip quotes if JSON-stringified
        let detailBytes = Array(rawDetail.utf8)
        if detailBytes.count >= 2, detailBytes.first == 34, detailBytes.last == 34 {
          let innerBytes = detailBytes[1..<detailBytes.count - 1]
          rawDetail = String(decoding: innerBytes, as: UTF8.self)
        }

        let query = rawDetail

        guard !query.isEmpty else { 
          return 
        }
        let encodedQuery = encodeURIComponent(query)
        // If resultUrlBase is "/articles", we use a direct query param, otherwise old style for Gnorium
        let targetUrl: String
        if stringEquals(resultUrlBase, "/articles") {
          targetUrl = "\(resultUrlBase)?\(searchField)=\(encodedQuery)"
        } else {
          targetUrl = "\(resultUrlBase)?value=\(encodedQuery)&field=\(searchField)"
        }
        window.location.href = targetUrl
      }
    }

    private struct SearchResultItem: Sendable {
      let id: Int
      let title: String
      let subtitle: String
      let urlSegment: String
      let homograph: Int
    }

    private func performSearch(query: String, typeahead: Element) {
      // Strip surrounding quotes if present (likely due to event serialization)
      // Use UTF8 bytes to detect quotes (34) to avoid Grapheme breaking dependency
      var cleanQuery = query
      let queryBytes = Array(query.utf8)
      if queryBytes.count >= 2, queryBytes.first == 34, queryBytes.last == 34 {
        let innerBytes = queryBytes[1..<queryBytes.count - 1]
        cleanQuery = String(decoding: innerBytes, as: UTF8.self)
      }

      // Encode query to be URL safe
      let encodedQuery = encodeURIComponent(cleanQuery)

      // If resultUrlBase is "/articles", we use a direct query param, otherwise old style for Gnorium
      let url: String
      if stringEquals(resultUrlBase, "/articles") {
        url = "\(searchEndpoint)?\(searchField)=\(encodedQuery)"
      } else {
        url = "\(searchEndpoint)?value=\(encodedQuery)&field=\(searchField)"
      }

      console.log("Performing search: \(url)")  // Debug log

      typeahead.fetch(url) { [self] (jsonString: String?) in
        guard let json = jsonString else {
          console.log("SearchDialogView: No JSONFormattable response received")
          return
        }

        console.log("SearchDialogView: Received JSONFormattable response")

        // Parse JSONFormattable results
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
        if (byte >= 65 && byte <= 90)  // A-Z
          || (byte >= 97 && byte <= 122)  // a-z
          || (byte >= 48 && byte <= 57)  // 0-9
          || byte == 45 || byte == 95 || byte == 46 || byte == 126
        {  // - _ . ~
          bytes.append(byte)
        } else {
          bytes.append(37)  // %
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

    private func updateTypeaheadMenu(typeahead: Element, results: [SearchResultItem]) {
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
        item.setAttribute(data("value"), result.title)
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
        item.style.transition(
          transitionPropertyBase, transitionDurationBase, transitionTimingFunctionUser)

        // Construct URL for navigation
        let href: String
        if stringEquals(resultUrlBase, "/articles") {
          href = "\(resultUrlBase)/\(result.urlSegment)"
        } else {
          href = "\(resultUrlBase)/\(result.urlSegment)/\(result.title)/\(result.homograph)"
        }
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
        label.textContent = result.title
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
        description.textContent = result.subtitle
        description.style.fontFamily(typographyFontSans)
        description.style.fontSize(fontSizeSmall14)
        description.style.fontWeight(fontWeightNormal)
        description.style.lineHeight(lineHeightSmall22)
        description.style.color(colorSubtle)

        textContent.appendChild(description)
        item.appendChild(textContent)

        // Add hover/active/focus event listeners for progressive styling
        _ = item.addEventListener(.mouseenter) { (event: Event) in
          item.style.color(colorBlue)
          item.style.border(borderWidthBase, .solid, borderColorBlue)
          item.style.cursor(cursorBaseHover)
        }

        _ = item.addEventListener(.mouseleave) { (event: Event) in
          item.style.color(colorSubtle)
          item.style.border(borderWidthBase, .solid, borderColorSubtle)
          item.style.cursor(cursorBase)
        }

        _ = item.addEventListener(.mousedown) { (event: Event) in
          item.style.color(colorBlue)
          item.style.border(borderWidthBase, .solid, borderColorBlue)
          item.style.cursor(cursorBaseHover)
        }

        _ = item.addEventListener(.mouseup) { (event: Event) in
          item.style.color(colorBlue)
          item.style.border(borderWidthBase, .solid, borderColorBlue)
          item.style.cursor(cursorBaseHover)
        }

        _ = item.addEventListener(.focus) { (event: Event) in
          item.style.color(colorBlueFocus)
          item.style.outline(borderWidthBase, .solid, borderColorBlueFocus)
          item.style.outlineOffset(px(-1))
        }

        _ = item.addEventListener(.blur) { (event: Event) in
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

    private func parseSearchResponse(_ json: String) -> [SearchResultItem]? {
      let jsonString = json

      // Manual JSONFormattable Parsing to avoid Foundation dependency in Wasm
      var results: [SearchResultItem] = []

      // Helper to extract JSONFormattable array
      func extractArray(from source: String, key: String) -> [String] {
        let searchKey = "\"\(key)\":"
        guard let keyOffset = stringIndexOf(source, searchKey) else { return [] }
        let keyLen = cStringLength(searchKey)
        let afterKey = stringSubstring(source, from: keyOffset + keyLen)

        guard let start = stringIndexOfChar(afterKey, CChar(UInt8(ascii: "["))),
          let end = stringIndexOfChar(afterKey, CChar(UInt8(ascii: "]")))
        else { return [] }

        let arrayContent = stringSubstring(afterKey, from: start + 1, to: end)
        if stringTrim(arrayContent).isEmpty { return [] }

        return splitJsonArray(arrayContent)
      }

      // Helper to split JSON array into object strings
      func splitJsonArray(_ arrayContent: String) -> [String] {
        var objects: [String] = []
        var braceDepth = 0
        var objStart = 0

        let bytes = Array(arrayContent.utf8)
        var i = 0
        while i < bytes.count {
          let char = bytes[i]
          if char == 123 {  // '{'
            if braceDepth == 0 {
              objStart = i
            }
            braceDepth += 1
          } else if char == 125 {  // '}'
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
            if char == UInt8(ascii: ",") || char == UInt8(ascii: "}")
              || isWhitespace(CChar(bitPattern: char))
            {
              break
            }
            valueBytes.append(char)
          }
          return String(decoding: valueBytes, as: UTF8.self)
        }
        return ""
      }

      let exactStrs = extractArray(from: jsonString, key: "exact")
      let partialStrs = extractArray(from: jsonString, key: "partial")

      var allStrs = exactStrs + partialStrs
      
      // If no exact/partial arrays found, try parsing as a simple array of objects
      if allStrs.isEmpty {
        let trimmed = stringTrim(jsonString)
        if stringStartsWith(trimmed, "[") && stringEndsWith(trimmed, "]") {
          let content = stringSubstring(trimmed, from: 1, to: cStringLength(trimmed) - 1)
          allStrs = splitJsonArray(content)
        }
      }

      for str in allStrs {
        let title = extractValue(from: str, key: resultTitleKey)
        let subtitle = extractValue(from: str, key: resultSubtitleKey)
        let urlSegment = extractValue(from: str, key: resultUrlKey)
        
        let homographStr = extractValue(from: str, key: "homograph")
        let homograph = safeParseInt(homographStr) ?? 1
        let idStr = extractValue(from: str, key: "id")
        let id = safeParseInt(idStr) ?? 0

        if !title.isEmpty {
          results.append(
            SearchResultItem(
              id: id,
              title: title,
              subtitle: subtitle,
              urlSegment: urlSegment,
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
      // Signal ellipsis menu to close (NavbarHydration listens)
      document.dispatchEvent(CustomEvent(type: "search-menu-opened", detail: "{}"))

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

          // Animate container (slide down from beneath navbar)
          if let container = menu.querySelector("[data-search-menu-container=\"true\"]") {
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

        // Animate out container (slide back up beneath navbar)
        if let container = menu.querySelector("[data-search-menu-container=\"true\"]") {
          container.style.opacity(0)
          container.style.transform(translateY(perc(-100)))
        }

        // Hide menu after animation
        window.setTimeout(250) {
          menu.style.display(.none)
          menu.style.pointerEvents(.none)
        }

        // Re-enable body scroll
        document.body.style.overflow(.auto)

        // Clear search input
        if let input = menu.querySelector("input") {
          (input as? HTMLInputElement)?.value = ""
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
