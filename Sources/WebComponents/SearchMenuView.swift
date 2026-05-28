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
    let resultTextKey: String
    let resultSubtextKey: String
    let resultUrlKey: String
    let resultPosKey: String
    let resultHomographKey: String
    let resultColorKey: String
    let tabs: [SearchMenuTab]
    let localStorageKey: String

    public struct SearchMenuTab: Sendable {
      let name: String
      let label: String
      let searchEndpoint: String
      let searchField: String
      let resultUrlBase: String
      let resultTextKey: String
      let resultSubtextKey: String
      let resultUrlKey: String
      let resultPosKey: String
      let resultHomographKey: String
      let resultColorKey: String

      public init(
        name: String, label: String,
        searchEndpoint: String, searchField: String,
        resultUrlBase: String,
        resultTextKey: String, resultSubtextKey: String, resultUrlKey: String,
        resultPosKey: String = "partsOfSpeech",
        resultHomographKey: String = "homograph",
        resultColorKey: String = "color"
      ) {
        self.name = name
        self.label = label
        self.searchEndpoint = searchEndpoint
        self.searchField = searchField
        self.resultUrlBase = resultUrlBase
        self.resultTextKey = resultTextKey
        self.resultSubtextKey = resultSubtextKey
        self.resultUrlKey = resultUrlKey
        self.resultPosKey = resultPosKey
        self.resultHomographKey = resultHomographKey
        self.resultColorKey = resultColorKey
      }
    }

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
      resultTextKey: String = "title",
      resultSubtextKey: String = "subtitle",
      resultUrlKey: String = "url",
      resultPosKey: String = "partsOfSpeech",
      resultHomographKey: String = "homograph",
      resultColorKey: String = "color",
      tabs: [SearchMenuTab] = [],
      localStorageKey: String = "search-tab"
    ) {
      self.id = id
      self.placeholder = placeholder
      self.results = results
      self.`class` = `class`
      self.searchField = searchField
      self.searchEndpoint = searchEndpoint
      self.resultUrlBase = resultUrlBase
      self.resultTextKey = resultTextKey
      self.resultSubtextKey = resultSubtextKey
      self.resultUrlKey = resultUrlKey
      self.resultPosKey = resultPosKey
      self.resultHomographKey = resultHomographKey
      self.resultColorKey = resultColorKey
      self.tabs = tabs
      self.localStorageKey = localStorageKey
    }

    private func tabConfigsJSON() -> String {
      var entries: [String] = []
      for tab in tabs {
        let esc = { (s: String) -> String in
          s.replacingOccurrences(of: "\\", with: "\\\\")
           .replacingOccurrences(of: "\"", with: "\\\"")
        }
        entries.append(
          "\"\(esc(tab.name))\":{"
          + "\"searchEndpoint\":\"\(esc(tab.searchEndpoint))\""
          + ",\"searchField\":\"\(esc(tab.searchField))\""
          + ",\"resultUrlBase\":\"\(esc(tab.resultUrlBase))\""
          + ",\"resultTextKey\":\"\(esc(tab.resultTextKey))\""
          + ",\"resultSubtextKey\":\"\(esc(tab.resultSubtextKey))\""
          + ",\"resultUrlKey\":\"\(esc(tab.resultUrlKey))\""
          + ",\"resultPosKey\":\"\(esc(tab.resultPosKey))\""
          + ",\"resultHomographKey\":\"\(esc(tab.resultHomographKey))\""
          + ",\"resultColorKey\":\"\(esc(tab.resultColorKey))\""          + "}"
        )
      }
      return "{\(entries.joined(separator: ","))}"
    }

    public func build() -> Node {
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
          // Search category tabs
          if !tabs.isEmpty {
            TabsView(
              tabs: tabs.map { TabView(name: $0.name, label: $0.label) {} },
              activeTab: tabs.first?.name ?? "",
              variant: .solid,
              class: "search-menu-tabs",
              fullWidth: true
            )
          }
            div {
              // Search input at top
              TypeaheadSearchView(
                id: id,
                formAction: resultUrlBase,
                highlightQuery: true,
                showThumbnail: false,
                autoExpandWidth: false,
                showEmptyQueryResults: false,
                placeholder: placeholder,
                searchIcon: true,
                class: "search-menu-typeahead"
              )
            }
            .style {
              display(.flex)
              flexDirection(.row)
              alignItems(.center)
            }

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
        .data("result-text-key", resultTextKey)
        .data("result-subtext-key", resultSubtextKey)
        .data("result-url-key", resultUrlKey)
        .data("result-pos-key", resultPosKey)
        .data("result-homograph-key", resultHomographKey)
        .data("result-color-key", resultColorKey)
        .data("local-storage-key", localStorageKey)
        .data("has-tabs", tabs.isEmpty ? "false" : "true")
        .data("tab-configs", tabConfigsJSON())
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
    private var resultTextKey: String = "title"
    private var resultSubtextKey: String = "subtitle"
    private var resultUrlKey: String = "url"
    private var resultPosKey: String = "partsOfSpeech"
    private var resultHomographKey: String = "homograph"
    private var resultColorKey: String = "color"
    private var localStorageKey: String = "search-tab"
    private var isMenuOpen: Bool = false

    public init() {}

    public func hydrate() {
      // Listen for search trigger clicks (navbar button)
      let searchTriggers = document.querySelectorAll("[data-search-trigger=\"true\"]")
      for searchTrigger in searchTriggers {
        _ = searchTrigger.addEventListener(.click) { [self] event in
          event.preventDefault()
          self.toggleMenu()
        }
      }

      let typeaheadElements = document.querySelectorAll(".search-menu-typeahead")
      for typeahead in typeaheadElements {
        hydrateTypeahead(typeahead)
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

      // Hydrate search functionality (already done above)

      // Close typeahead dropdown when clicking outside the typeahead
      document.addEventListener(.click) { event in
        let target = event.target
        for typeahead in typeaheadElements {
          guard let menu = typeahead.querySelector(".typeahead-search-menu") else { continue }
          var el = target
          var inside = false
          while el != nil {
            if el === typeahead { inside = true; break }
            el = el?.parentElement
          }
          if !inside {
            menu.style.display(.none)
            if !self.isMenuOpen {
              document.body.style.overflow(.auto)
            }
          }
        }
      }

      // Tab switching for search category
      let tabButtons = document.querySelectorAll(".search-menu-tabs [role='tab']")

      // Read localStorageKey and tab configs from container
      guard let container = document.querySelector("[data-search-menu-container=\"true\"]") else { return }
      let lsKey = container.dataset["localStorageKey"] ?? "search-tab"
      let rawTabConfigs = container.dataset["tabConfigs"] ?? "{}"

      // Restore saved tab from localStorage
      if let savedTab = localStorage.getItem(lsKey), !stringIsEmpty(savedTab) {
        for btn in tabButtons {
          if stringEquals(btn.getAttribute(data("tab-name")) ?? "", savedTab) {
            btn.click()
            break
          }
        }
      }

      for button in tabButtons {
        _ = button.addEventListener(.click) { [self] _ in
          guard let tabName = button.getAttribute(data("tab-name")),
                let container = document.querySelector("[data-search-menu-container=\"true\"]")
          else { return }

          localStorage.setItem(lsKey, tabName)

          // Read tab config from the serialized JSON on container
          searchEndpoint = extractJSONValue(rawTabConfigs, tabName, "searchEndpoint") ?? "/api/search"
          searchField = extractJSONValue(rawTabConfigs, tabName, "searchField") ?? "q"
          resultUrlBase = extractJSONValue(rawTabConfigs, tabName, "resultUrlBase") ?? "/results"
          resultTextKey = extractJSONValue(rawTabConfigs, tabName, "resultTextKey") ?? "text"
          resultSubtextKey = extractJSONValue(rawTabConfigs, tabName, "resultSubtextKey") ?? "language"
          resultUrlKey = extractJSONValue(rawTabConfigs, tabName, "resultUrlKey") ?? "id"
          resultPosKey = extractJSONValue(rawTabConfigs, tabName, "resultPosKey") ?? "partsOfSpeech"
          resultHomographKey = extractJSONValue(rawTabConfigs, tabName, "resultHomographKey") ?? "homograph"
          resultColorKey = extractJSONValue(rawTabConfigs, tabName, "resultColorKey") ?? "color"

          // Update data attributes for persistence
          _ = container.dataset["searchEndpoint"] = searchEndpoint
          _ = container.dataset["searchField"] = searchField
          _ = container.dataset["resultUrlBase"] = resultUrlBase
          _ = container.dataset["resultTextKey"] = resultTextKey
          _ = container.dataset["resultSubtextKey"] = resultSubtextKey
          _ = container.dataset["resultUrlKey"] = resultUrlKey
          _ = container.dataset["resultPosKey"] = resultPosKey
          _ = container.dataset["resultHomographKey"] = resultHomographKey
          _ = container.dataset["resultColorKey"] = resultColorKey

          // Clear current results and re-search with current query
          if let typeahead = document.querySelector(".search-menu-typeahead"),
             let input = typeahead.querySelector("input") as? HTMLInputElement
          {
            if let menu = typeahead.querySelector(".typeahead-search-menu") {
              menu.innerHTML = ""
              menu.style.display(.none)
            }
            let query = input.value
            if !stringIsEmpty(query) {
              self.performSearch(query: query, typeahead: typeahead)
            }
          }
        }
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

      resultTextKey = container.dataset["resultTextKey"] ?? "title"
      resultSubtextKey = container.dataset["resultSubtextKey"] ?? "subtitle"
      resultUrlKey = container.dataset["resultUrlKey"] ?? "url"
      resultPosKey = container.dataset["resultPosKey"] ?? "partsOfSpeech"
      resultHomographKey = container.dataset["resultHomographKey"] ?? "homograph"
      resultColorKey = container.dataset["resultColorKey"] ?? "color"

      // Ensure input exists but we don't need the reference
      guard typeahead.querySelector("input") != nil else {
        return
      }

      // Click on the form area re-shows the dropdown if it was dismissed
      if let form = typeahead.querySelector(".typeahead-search-form") {
        _ = form.addEventListener(.click) { _ in
          if let menu = typeahead.querySelector(".typeahead-search-menu") {
            let display = menu.style.getPropertyValue(.display)
            if stringEquals(display, "none") {
              menu.style.display(.flex)
            }
          }
        }
      }

      // Listen for custom 'typeahead-input' event from TypeaheadSearchInstance
      typeahead.addEventListener("typeahead-input") { [self] event in


        var rawDetail = event.detail

        let detailBytes = Array(rawDetail.utf8)
        if detailBytes.count >= 2, detailBytes.first == 34, detailBytes.last == 34 {
          let innerBytes = detailBytes[1..<detailBytes.count - 1]
          rawDetail = String(decoding: innerBytes, as: UTF8.self)
        }

        let query = rawDetail

        guard !query.isEmpty else {
          if let menu = typeahead.querySelector(".typeahead-search-menu") {
            menu.innerHTML = ""
            menu.style.display(.none)
          }
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

        if stringIsEmpty(query) {
          window.location.href = resultUrlBase
          return
        }
        let encodedQuery = encodeURIComponent(query)
        let targetUrl = "\(resultUrlBase)?\(searchField)=\(encodedQuery)"
        window.location.href = targetUrl
      }
    }

    private struct SearchResultItem: Sendable {
      let id: Int
      let text: String
      let subtext: String
      let pos: String
      let urlSegment: String
      let homograph: Int
      let color: String
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

      let url = "\(searchEndpoint)?\(searchField)=\(encodedQuery)"

      typeahead.fetch(url) { [self] (jsonString: String?) in
        guard let json = jsonString else { return }

        if let results = self.parseSearchResponse(json) {
          self.updateTypeaheadMenu(typeahead: typeahead, results: results)
        }
      }
    }

    /// Extract a string value from a JSON object keyed by tab name.
    /// JSON format: {"tabName":{"key":"value",...}}
    /// Uses manual parsing (no Foundation dependency).
    private func extractJSONValue(_ json: String, _ tabName: String, _ key: String) -> String? {
      // Find tabName key
      let tabSearch = "\"\(tabName)\":"
      guard let tabOffset = stringIndexOf(json, tabSearch) else { return nil }
      let afterTab = stringSubstring(json, from: tabOffset + cStringLength(tabSearch))
      // Find key in the tab's object
      let keySearch = "\"\(key)\":\""
      guard let keyOffset = stringIndexOf(afterTab, keySearch) else { return nil }
      let afterKey = stringSubstring(afterTab, from: keyOffset + cStringLength(keySearch))
      // Read until closing quote
      var result: [UInt8] = []
      for byte in Array(afterKey.utf8) {
        if byte == 34 { break }  // "
        if byte == 92 { continue }  // \ skip escape
        result.append(byte)
      }
      return result.isEmpty ? nil : String(decoding: result, as: UTF8.self)
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
      if results.isEmpty {
        if let existing = typeahead.querySelector(".typeahead-search-menu") {
          existing.style.display(.none)
        }
        return
      }

      let limitedResults = Array(results.prefix(16))

      let menu: Element
      if let existing = typeahead.querySelector(".typeahead-search-menu") {
        menu = existing
      } else {
        menu = document.createElement(.div)
        menu.className = "typeahead-search-menu"
        typeahead.appendChild(menu)
      }
      menu.style.display(.flex)
      menu.style.flexDirection(.column)
      menu.style.gap(spacing8)
      menu.style.maxHeight(calc(vh(100) - px(256)))
      menu.style.overflowY(.auto)

      menu.innerHTML = ""

      // Create new menu items using DOM API
      for result in limitedResults {
        let item = document.createElement(.div)
        item.className = "menu-item-view"
        item.setAttribute(data("value"), result.text)
        item.setAttribute(.role, .option)
        item.setAttribute(.tabindex, -1)

        // Apply menu item styles
        item.style.display(.flex)
        item.style.alignItems(.center)
        item.style.gap(spacing12)
        item.style.padding(spacing8, spacing12)
        item.style.minHeight(spacing64)
        item.style.fontFamily(typographyFontSans)
        item.style.fontSize(fontSizeMedium16)
        item.style.lineHeight(lineHeightSmall22)
        item.style.color(colorBase)
        item.style.backgroundColor(backgroundColorTransparent)
        item.style.border(borderWidthBase, .solid, borderColorSubtle)
        item.style.borderRadius(borderRadiusBase)
        item.style.cursor(cursorBase)
        item.style.userSelect(.none)
        item.style.textDecoration(textDecorationNone)
        item.style.boxSizing(.borderBox)
        item.style.transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionUser)

        // Construct URL for navigation
        let href: String
        let base = stripQuery(resultUrlBase)
        if stringEquals(searchField, "q") || stringContains(resultUrlBase, "/articles") {
          href = "\(base)/\(result.urlSegment)"
        } else {
          href = "\(base)/\(result.urlSegment)/\(result.text)/\(result.homograph)"
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
        let textWrapper = document.createElement(.span)
        textWrapper.className = "menu-item-title"
        textWrapper.style.display(.flex)
        textWrapper.style.alignItems(.center)
        textWrapper.style.gap(spacing4)

        // Title label
        let label = document.createElement(.span)
        label.className = "menu-item-label"
        label.textContent = result.text
        label.style.fontFamily(typographyFontSans)
        label.style.fontSize(fontSizeMedium16)
        label.style.fontWeight(fontWeightNormal)
        label.style.lineHeight(lineHeightSmall22)
        label.style.setProperty(.color, `var`("--color-\(result.color)"))
        label.style.opacity(1)

        textWrapper.appendChild(label)

        // POS + homograph superscript after lemma
        if !stringIsEmpty(result.pos) {
          let posSpan = document.createElement(.span)
          posSpan.className = "menu-item-pos"
          posSpan.textContent = result.pos
          posSpan.style.fontFamily(typographyFontSans)
          posSpan.style.fontSize(fontSizeSmall14)
          posSpan.style.fontWeight(fontWeightNormal)
          posSpan.style.lineHeight(lineHeightSmall22)
          posSpan.style.color(colorSubtle)
          textWrapper.appendChild(posSpan)

          if result.homograph > 1 {
            let posSup = document.createElement(.sup)
            posSup.textContent = "\(result.homograph)"
            posSup.style.fontSize(fontSizeSmall14)
            posSup.style.color(colorSubtle)
            textWrapper.appendChild(posSup)
          }
        }
        textContent.appendChild(textWrapper)

        // Description
        let description = document.createElement(.span)
        description.className = "menu-item-description"
        description.textContent = result.subtext
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
          item.style.outline(borderWidthBase, .solid, borderColorBlue)
          item.style.outlineOffset(px(-2))
          item.style.cursor(cursorBaseHover)
          if let label = item.querySelector(".menu-item-label") {
            label.style.color(colorBlue)
          }
          if let pos = item.querySelector(".menu-item-pos") {
            pos.style.color(colorBase)
          }
          if let desc = item.querySelector(".menu-item-description") {
            desc.style.color(colorBase)
          }
        }

        _ = item.addEventListener(.mouseleave) { (event: Event) in
          item.style.color(colorSubtle)
          item.style.border(borderWidthBase, .solid, borderColorSubtle)
          item.style.outline(.none)
          item.style.cursor(cursorBase)
          if let label = item.querySelector(".menu-item-label") {
            label.style.color(colorBase)
          }
          if let pos = item.querySelector(".menu-item-pos") {
            pos.style.color(colorSubtle)
          }
          if let desc = item.querySelector(".menu-item-description") {
            desc.style.color(colorSubtle)
          }
        }

        _ = item.addEventListener(.mousedown) { (event: Event) in
          item.style.color(colorBlue)
          item.style.border(borderWidthBase, .solid, borderColorBlue)
          item.style.outline(borderWidthBase, .solid, borderColorBlue)
          item.style.outlineOffset(px(-2))
          item.style.cursor(cursorBaseHover)
        }

        _ = item.addEventListener(.mouseup) { (event: Event) in
          item.style.color(colorBlue)
          item.style.border(borderWidthBase, .solid, borderColorBlue)
          item.style.outline(borderWidthBase, .solid, borderColorBlue)
          item.style.outlineOffset(px(-2))
          item.style.cursor(cursorBaseHover)
        }

        _ = item.addEventListener(.focus) { (event: Event) in
          item.style.color(colorBlueFocus)
          item.style.outline(borderWidthBase, .solid, borderColorBlueFocus)
          item.style.outlineOffset(px(-2))
        }

        _ = item.addEventListener(.blur) { (event: Event) in
          item.style.color(colorSubtle)
          item.style.outline(.none)
        }

        _ = item.addEventListener(.click) { _ in
          if let url = item.getAttribute(data("url")), !stringIsEmpty(url) {
            window.location.href = url
          }
          let value = item.getAttribute(data("value")) ?? ""
          let event = CustomEvent(type: "search-result-click", detail: value)
          typeahead.dispatchEvent(event)
        }

        menu.appendChild(item)
      }

      // Dispatch event for TypeaheadSearchInstance to re-scan menu items
      typeahead.dispatchEvent(CustomEvent(type: "typeahead-menu-updated", detail: "{}"))

      // Lock body scroll when dropdown is shown
      if !results.isEmpty {
        document.body.style.overflow(.hidden)
      }
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
        let textValue = extractValue(from: str, key: resultTextKey)
        let subtextValue = extractValue(from: str, key: resultSubtextKey)
        let urlSegment = extractValue(from: str, key: resultUrlKey)
        let posValue = extractValue(from: str, key: resultPosKey)
        
        let homographStr = extractValue(from: str, key: resultHomographKey)
        let homograph = parseInt(homographStr) ?? 1
        let idStr = extractValue(from: str, key: "id")
        let id = parseInt(idStr) ?? 0

        let colorValue = extractValue(from: str, key: resultColorKey)
        let color = colorValue.isEmpty ? "blue" : colorValue

        if !textValue.isEmpty {
          results.append(
            SearchResultItem(
              id: id,
              text: textValue,
              subtext: subtextValue,
              pos: posValue,
              urlSegment: urlSegment,
              homograph: homograph,
              color: color
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
        menu.style.display(.flex)
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

    private func stripQuery(_ url: String) -> String {
      let parts = stringSplit(url, separator: "?")
      return parts.count > 0 ? parts[0] : url
    }
  }
#endif
