#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// Tabs consist of two or more tab items for navigating between different sections of content.
  public struct TabsView: HTMLContent {
    let tabs: [TabView]
    let activeTab: String?
    let framed: Bool
    let variant: Variant
    let `class`: String
    let fullWidth: Bool
    let localStorageKey: String?
    /// Which query parameter carries this tab set's selection.
    /// Two tab sets can share a page — Mission Control has one per room —
    /// and they cannot both be "tab".
    let queryParam: String

    /// Visual style variant for tab buttons
    public enum Variant: String, Sendable {
      /// Underline active tab, transparent background
      case quiet
      /// Pill-shaped tabs, filled background on active tab
      case solid
    }

    public init(
      tabs: [TabView],
      activeTab: String? = nil,
      framed: Bool = false,
      variant: Variant = .quiet,
      class: String = "",
      fullWidth: Bool = false,
      localStorageKey: String? = nil,
      queryParam: String = "tab"
    ) {
      self.tabs = tabs
      self.activeTab = activeTab ?? tabs.first?.name
      self.framed = framed
      self.variant = variant
      self.`class` = `class`
      self.fullWidth = fullWidth
      self.localStorageKey = localStorageKey
      self.queryParam = queryParam
    }

    public func build() -> DOM.Node {
      let active = activeTab ?? tabs.first?.name ?? ""

      return div {
        div {
          // Scroll buttons only for quiet variant (solid wraps instead)
          if variant == .quiet {
            button { PreviousIconView() }
              .type(.button)
              .class("tabs-scroll-button tabs-scroll-prev")
              .ariaLabel("Scroll to previous tabs")
              .data("scroll", "prev")
              .data("visible", false)
          }

          div {
            for tab in tabs {
              let tabClass = tab.`class`.isEmpty ? "tab-view" : "tab-view \(tab.`class`)"

              if let url = tab.url {
                // URL tabs render as anchor links (navigation)
                a { tab.label.isEmpty ? tab.name : tab.label }
                  .href(url)
                  .class(tabClass)
                  .role("tab")
                  .ariaSelected(tab.name == active)
                  .id("tab-\(tab.name)")
                  .data("tab-name", tab.name)
              } else {
                // Panel-switching tabs render as buttons
                button { tab.label.isEmpty ? tab.name : tab.label }
                  .type(.button)
                  .class(tabClass)
                  .role("tab")
                  .ariaSelected(tab.name == active)
                  .ariaControls("panel-\(tab.name)")
                  .id("tab-\(tab.name)")
                  .data("tab-name", tab.name)
                  .disabled(tab.disabled)
                  .tabindex(tab.name == active ? 0 : -1)
              }
            }
          }
          .class("tabs-list")
          .role("tablist")

          if variant == .quiet {
            button { NextIconView() }
              .type(.button)
              .class("tabs-scroll-button tabs-scroll-next")
              .ariaLabel("Scroll to next tabs")
              .data("scroll", "next")
              .data("visible", false)
          }
        }
        .class("tabs-header")

        for tab in tabs {
          let isActive = tab.name == active
          section {
            tab.content
          }
          .class("tab-panel")
          .role("tabpanel")
          .id("panel-\(tab.name)")
          .ariaLabelledby("tab-\(tab.name)")
          .tabindex(0)
          .hidden(!isActive)
        }
      }
      .class(
        [
          "tabs-view",
          framed ? "tabs-framed" : nil,
          fullWidth ? "tabs-full-width" : nil,
          "tabs-\(variant.rawValue)",
          `class`.isEmpty ? nil : `class`,
        ].compactMap { $0 }.joined(separator: " ")
      )
      .data("active-tab", active)
      .data("local-storage-key", localStorageKey ?? "")
      .data("query-param", queryParam)
      // ZERO REPETITION — every selector and property is declared exactly once
      // in this single style block. The descendant/child/selector chains below
      // cover every visual state for the root, header, list, both tab button
      // variants (<a> and <button>), scroll buttons, and panels.
      .style {
        // Self — root .tabs-view container
        selector("&") {
          display(.block)
          fontFamily(typographyFontSans)
        }
        selector("&.tabs-framed") {
          border(borderWidthBase, .solid, borderColorSubtle)
          borderRadius(borderRadiusBase)
        }
        selector("&.tabs-full-width") {
          width(perc(100))
        }

        // Header strip wrapping the scroll buttons + tab list
        child(".tabs-header") {
          display(.flex)
          alignItems(.center)
          position(.relative)
          overflow(.hidden)
        }
        selector("&.tabs-quiet > .tabs-header") { gap(0) }
        selector("&.tabs-solid > .tabs-header") { gap(spacing4) }

        // Tab list (the .tabs-list row holding every tab button)
        child(".tabs-header .tabs-list") {
          display(.flex)
          margin(0)
          padding(0)
          listStyle(.none)
          flexGrow(1)
        }
        selector("&.tabs-quiet > .tabs-header .tabs-list") {
          gap(spacing4)
          overflow(.auto)
          scrollbarWidth(.none)
          pseudoElement(.webkitScrollbar) { display(.none).important() }
        }
        selector("&.tabs-solid > .tabs-header .tabs-list") {
          gap(spacing8)
          flexWrap(.wrap)
        }

        // Tab buttons — ONE rule chain covers both <a> and <button> tags
        selector("& [role='tab']") {
          display(.flex)
          alignItems(.center)
          justifyContent(.center)
          whiteSpace(.nowrap)
          textAlign(.center)
          border(.none)
          cursor(cursorBaseHover)
          transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
          position(.relative)
          fontFamily(typographyFontSans)
          backgroundColor(.transparent)
          borderRadius(borderRadiusPill)
          textDecoration(.none)
        }
        selector("&.tabs-full-width [role='tab']") { flex(1) }
        selector("&.tabs-quiet [role='tab']") {
          height(px(44))
          padding(0, spacing12)
          fontSize(fontSizeSmall14)
          fontWeight(fontWeightNormal)
          lineHeight(lineHeightSmall22)
        }
        selector("&.tabs-solid [role='tab']") {
          padding(spacing8, spacing16)
          fontSize(fontSizeSmall14)
          lineHeight(lineHeightXSmall20)
        }
        selector("&.tabs-quiet [role='tab'][aria-selected='true']") {
          cursor(.default)
          color(colorBase)
          fontWeight(fontWeightSemiBold)
        }
        selector("&.tabs-solid [role='tab'][aria-selected='true']") {
          cursor(.default)
          color(colorInvertedFixed)
          backgroundColor(colorBlue)
          fontWeight(fontWeightBold)
        }
        selector("&.tabs-quiet [role='tab'][aria-selected='false']") { color(colorSubtle) }
        selector("&.tabs-solid [role='tab'][aria-selected='false']") { color(colorBlue) }
        selector("&.tabs-solid [role='tab']:hover[aria-selected='false']") {
          backgroundColor(backgroundColorInteractiveSubtleHover)
          color(colorBase)
        }
        selector("& [role='tab']:focus-visible") {
          outline(borderWidthThick, .solid, borderColorBlue)
          outlineOffset(px(-2))
        }
        selector("&.tabs-solid [role='tab']:active") {
          backgroundColor(colorBlue)
          color(colorInvertedFixed)
          outline(.none)
        }
        selector("& [role='tab'].disabled", "& [role='tab'][disabled]", "& [role='tab'][aria-disabled='true']") {
          color(colorDisabled)
          cursor(cursorNotAllowed)
          pointerEvents(.none)
        }

        // Scroll buttons (only rendered for quiet variant)
        descendant(".tabs-scroll-button") {
          display(.none)
          alignItems(.center)
          justifyContent(.center)
          width(sizeIconMedium)
          height(perc(100))
          padding(spacing8)
          backgroundColor(backgroundColorBase)
          border(.none)
          cursor(cursorBaseHover)
          flexShrink(0)
          color(colorBase)

          pseudoClass(.hover) {
            backgroundColor(backgroundColorInteractiveSubtleHover).important()
          }
          pseudoClass(.active) {
            backgroundColor(backgroundColorInteractiveSubtleActive).important()
          }
          pseudoClass(.disabled) {
            color(colorDisabled).important()
            cursor(cursorNotAllowed).important()
          }
        }
        descendant(".tabs-scroll-button[data-visible='true']") {
          display(.flex)
        }

        // Tab panels
        selector("&.tabs-framed .tab-panel") { padding(spacing16) }
      }
    }
  }
#endif

// MARK: - Client-side hydration
#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  // (Client-side hydration code unchanged — copied from original file)

  /// JavaScript TabsInstance handles hydration of one TabsView in the DOM.
  final class TabsInstance: @unchecked Sendable {
    private let tabsElement: DOM.Element
    private var tabButtons: [DOM.Element] = []
    private var tabPanels: [DOM.Element] = []
    private var scrollPrevButton: DOM.Element?
    private var scrollNextButton: DOM.Element?
    private var tabsList: DOM.Element?
    private var activeTabName: String = ""

    init(tabs: DOM.Element) {
      self.tabsElement = tabs
      self.tabButtons = Array(tabs.querySelectorAll(".tabs-list [role='tab']"))
      self.tabPanels = Array(tabs.querySelectorAll(".tab-panel"))
      self.scrollPrevButton = tabs.querySelector("[\(data("scroll"))='prev']")
      self.scrollNextButton = tabs.querySelector("[\(data("scroll"))='next']")
      self.tabsList = tabs.querySelector(".tabs-list")
      self.activeTabName = tabs.getAttribute(data("active-tab")) ?? ""

      bindEvents()
      updateScrollButtons()
      restoreOrSaveTabPreference()
    }

    private func restoreOrSaveTabPreference() {
      let lsKey = tabsElement.getAttribute(data("local-storage-key")) ?? ""
      guard !stringIsEmpty(lsKey) else { return }

      // Not a hardcoded "tab": Mission Control carries two tab sets, one per
      // room, and each names its own parameter.
      var param = tabsElement.getAttribute(data("query-param")) ?? ""
      if stringIsEmpty(param) { param = "tab" }

      // Split on "&" rather than hunting a byte offset: that needs the key's
      // length, and counting a String's characters is what drags Unicode
      // normalisation into embedded WASM. It also anchors the match, so "tab="
      // can no longer be found inside "&othertab=".
      let key = "\(param)="
      var queryTab: String? = nil
      for pair in stringSplit(stringRemovePrefix(location.search, "?"), separator: "&") {
        if stringStartsWith(pair, key) {
          queryTab = stringRemovePrefix(pair, key)
        }
      }

      if let tab = queryTab, !stringIsEmpty(tab) {
        localStorage.setItem(lsKey, tab)
        return
      }

      guard let saved = localStorage.getItem(lsKey), !stringIsEmpty(saved) else { return }

      // The guard that matters: the saved tab may already BE the rendered one.
      // Without this, two tab sets on one page each navigate to restore
      // themselves, undoing the other, and the page ping-pongs forever.
      let active = tabsElement.getAttribute(data("active-tab")) ?? ""
      if stringEquals(active, saved) { return }

      for button in tabButtons {
        guard stringEquals(button.getAttribute(data("tab-name")) ?? "", saved) else { continue }

        // Panel tabs switch in place; only link tabs need a page.
        guard let url = button.getAttribute(.href), !stringIsEmpty(url) else {
          selectTab(saved, setFocus: false)
          return
        }

        // Not that href: it was rendered with the SIBLING tab set's current
        // value baked in, so following it writes that value back as the
        // sibling's preference and quietly discards the one it had saved.
        // Restoring touches this set's own parameter and nothing else.
        var pairs: [String] = []
        var replaced = false
        for pair in stringSplit(stringRemovePrefix(location.search, "?"), separator: "&") {
          if stringIsEmpty(pair) { continue }
          if stringStartsWith(pair, key) {
            pairs.append("\(key)\(saved)")
            replaced = true
          } else {
            pairs.append(pair)
          }
        }
        if !replaced { pairs.append("\(key)\(saved)") }

        location.href = "\(location.pathname)?\(stringJoin(pairs, separator: "&"))"
        return
      }
    }

    private func bindEvents() {
      for button in tabButtons {
        _ = button.addEventListener(.click) { [self, button] _ in
          guard let tabName = button.getAttribute(data("tab-name")) else { return }
          self.selectTab(tabName, setFocus: false)
        }

        _ = button.addEventListener(.keydown) { [self, button] (event: Event) in
          let key = event.key
          self.handleKeydown(key: key, currentButton: button)
        }
      }

      if let prevBtn = scrollPrevButton {
        _ = prevBtn.addEventListener(.click) { [self] _ in
          self.scrollTabs(direction: -1)
        }
      }

      if let nextBtn = scrollNextButton {
        _ = nextBtn.addEventListener(.click) { [self] _ in
          self.scrollTabs(direction: 1)
        }
      }

      if let list = tabsList {
        _ = list.addEventListener(.scroll) { [self] _ in
          self.updateScrollButtons()
        }
      }
    }

    private func selectTab(_ tabName: String, setFocus: Bool) {
      activeTabName = tabName

      let lsKey = tabsElement.getAttribute(data("local-storage-key")) ?? ""
      if !stringIsEmpty(lsKey) {
        localStorage.setItem(lsKey, tabName)
      }

      for button in tabButtons {
        let isActive = stringEquals(button.getAttribute(data("tab-name")) ?? "", tabName)
        button.setAttribute(.ariaSelected, isActive ? true : false)
        button.setAttribute(.tabindex, isActive ? 0 : -1)

        if isActive {
          _ = button.classList.add("tab-active")
          if setFocus { button.focus() }
        } else {
          _ = button.classList.remove("tab-active")
        }
      }

      for panel in tabPanels {
        if let panelID = panel.getAttribute(.id) {
          let shouldShow = stringEquals(panelID, "panel-\(tabName)")
          if shouldShow {
            panel.removeAttribute(.hidden)
          } else {
            panel.setAttribute(.hidden, "")
          }
        }
      }

      tabsElement.setAttribute(data("active-tab"), tabName)

      let event = CustomEvent(type: "update:active", detail: tabName)
      tabsElement.dispatchEvent(event)
    }

    private func handleKeydown(key: String, currentButton: DOM.Element) {
      let currentID = currentButton.getAttribute(.id) ?? ""
      guard
        let currentIndex = tabButtons.firstIndex(where: {
          stringEquals($0.getAttribute(.id) ?? "", currentID)
        })
      else { return }

      var targetIndex: Int?

      if stringEquals(key, "ArrowLeft") || stringEquals(key, "Left") {
        targetIndex = currentIndex > 0 ? currentIndex - 1 : tabButtons.count - 1
      } else if stringEquals(key, "ArrowRight") || stringEquals(key, "Right") {
        targetIndex = currentIndex < tabButtons.count - 1 ? currentIndex + 1 : 0
      } else if stringEquals(key, "Home") {
        targetIndex = 0
      } else if stringEquals(key, "End") {
        targetIndex = tabButtons.count - 1
      }

      if let index = targetIndex {
        let targetButton = tabButtons[index]
        guard let tabName = targetButton.getAttribute(data("tab-name")) else { return }
        selectTab(tabName, setFocus: true)
      }
    }

    private func scrollTabs(direction: Int) {
      guard let list = tabsList else { return }
      let scrollAmount = 200.0 * Double(direction)
      list.scrollBy(x: scrollAmount, y: 0)
    }

    private func updateScrollButtons() {
      guard let list = tabsList,
        let prev = scrollPrevButton,
        let next = scrollNextButton
      else { return }

      let hasOverflow = list.scrollWidth > list.clientWidth
      let canScrollLeft = list.scrollLeft > 0
      let canScrollRight = list.scrollLeft < (list.scrollWidth - list.clientWidth - 1)

      if hasOverflow {
        prev.setAttribute(data("visible"), "true")
        next.setAttribute(data("visible"), "true")

        if canScrollLeft {
          prev.removeAttribute(data("disabled"))
        } else {
          prev.setAttribute(data("disabled"), "")
        }

        if canScrollRight {
          next.removeAttribute(data("disabled"))
        } else {
          next.setAttribute(data("disabled"), "")
        }
      } else {
        prev.setAttribute(data("visible"), "false")
        next.setAttribute(data("visible"), "false")
      }
    }
  }

  public class TabsHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: TabsHydration?
    private var instances: [TabsInstance] = []

    public init() {
      hydrateAllTabs()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".tabs-view") != nil else { return }
      instance = TabsHydration()
    }

    private func hydrateAllTabs() {
      let allTabs = document.querySelectorAll(".tabs-view")

      for tabs in allTabs {
        let instance = TabsInstance(tabs: tabs)
        instances.append(instance)
      }
    }
  }
#endif
