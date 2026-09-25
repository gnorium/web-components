#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A Menu displays a list of available options, suggestions, or actions.
  public struct MenuView: HTMLContent {
    let menuItems: [MenuItemView.MenuItemData]
    let menuGroups: [MenuGroupData]
    let footer: MenuItemView.MenuItemData?
    let selected: [String]
    let expanded: Bool
    let showPending: Bool
    let visibleItemLimit: Int?
    let showThumbnail: Bool
    let boldLabel: Bool
    let hideDescriptionOverflow: Bool
    let searchQuery: String
    let multiselect: Bool
    let pendingContent: [DOM.Node]
    let noResultsContent: [DOM.Node]
    let showNoResultsSlot: Bool?
    let `class`: String

    /// Data structure for menu groups (groups multiple MenuItems)
    public struct MenuGroupData: Sendable {
      let title: String
      let hideTitle: Bool
      let description: String?
      let icon: String?
      let items: [MenuItemView.MenuItemData]

      public init(
        title: String,
        hideTitle: Bool = false,
        description: String? = nil,
        icon: String? = nil,
        items: [MenuItemView.MenuItemData]
      ) {
        self.title = title
        self.hideTitle = hideTitle
        self.description = description
        self.icon = icon
        self.items = items
      }
    }

    public init(
      menuItems: [MenuItemView.MenuItemData] = [],
      menuGroups: [MenuGroupData] = [],
      footer: MenuItemView.MenuItemData? = nil,
      selected: [String] = [],
      expanded: Bool = false,
      showPending: Bool = false,
      visibleItemLimit: Int? = nil,
      showThumbnail: Bool = false,
      boldLabel: Bool = false,
      hideDescriptionOverflow: Bool = false,
      searchQuery: String = "",
      multiselect: Bool = false,
      showNoResultsSlot: Bool? = nil,
      class: String = "",
      @HTMLBuilder pending: () -> [DOM.Node] = { [] },
      @HTMLBuilder noResults: () -> [DOM.Node] = { [] }
    ) {
      self.menuItems = menuItems
      self.menuGroups = menuGroups
      self.footer = footer
      self.selected = selected
      self.expanded = expanded
      self.showPending = showPending
      self.visibleItemLimit = visibleItemLimit
      self.showThumbnail = showThumbnail
      self.boldLabel = boldLabel
      self.hideDescriptionOverflow = hideDescriptionOverflow
      self.searchQuery = searchQuery
      self.multiselect = multiselect
      self.showNoResultsSlot = showNoResultsSlot
      self.`class` = `class`
      self.pendingContent = pending()
      self.noResultsContent = noResults()
    }

    public func build() -> DOM.Node {
      let hasVisibleLimit = visibleItemLimit != nil && visibleItemLimit! > 0
      let allItems = menuItems + menuGroups.flatMap { $0.items }
      let hasItems = !allItems.isEmpty
      let shouldShowNoResults = showNoResultsSlot ?? !hasItems
      let hasGroups = !menuGroups.isEmpty
      let hasPendingContent = !pendingContent.isEmpty
      let limitClass = hasVisibleLimit ? " menu-has-visible-limit menu-visible-limit-\(visibleItemLimit!)" : ""
      let menuClass = `class`.isEmpty ? "menu-view\(limitClass)" : "menu-view\(limitClass) \(`class`)"

      // Render individual menu item using MenuItemView
      func renderMenuItem(_ item: MenuItemView.MenuItemData, itemIndex: Int, isFooter: Bool = false)
        -> MenuItemView
      {
        let isSelected = selected.contains(item.value)
        let thumbnail =
          item.thumbnail != nil ? MenuItemView.Thumbnail(url: item.thumbnail!, alt: "") : nil

        return MenuItemView(
          id: "menu-item-\(itemIndex)",
          value: item.value,
          disabled: item.disabled,
          selected: isSelected,
          label: item.label ?? "",
          icon: item.icon,
          showThumbnail: showThumbnail,
          thumbnail: thumbnail,
          description: item.description,
          searchQuery: searchQuery,
          boldLabel: boldLabel,
          hideDescriptionOverflow: hideDescriptionOverflow,
          multiselect: multiselect,
          class: isFooter ? "menu-footer-item" : ""
        )
      }

      let itemIndex = 0

      return div {
        ul {
          // Pending state
          if showPending {
            li {
              ProgressBarView(inline: true)

              if hasPendingContent && !hasItems {
                div { pendingContent }
                  .class("menu-pending-content")
              }
            }
            .class("menu-pending")
          }

          // No results message
          if shouldShowNoResults && !noResultsContent.isEmpty && !showPending {
            li {
              noResultsContent
            }
            .class("menu-no-results")
          }

          // Menu groups
          if hasGroups {
            for (index, group) in menuGroups.enumerated() {
              li {
                // Group divider (for visually-hidden titles)
                if group.hideTitle && index > 0 {
                  hr()
                    .class("menu-group-divider")
                    .ariaHidden(true)
                }

                // Group header
                div {
                  h3 { group.title }
                    .class("menu-group-title")
                    .data("hidden", group.hideTitle)

                  if let desc = group.description {
                    p { desc }
                      .class("menu-group-description")
                  }
                }
                .class("menu-group-header")
                .data("title-hidden", group.hideTitle)

                // Group items
                ul {
                  for (offset, item) in group.items.enumerated() {
                    let currentIndex = itemIndex + offset
                    renderMenuItem(item, itemIndex: currentIndex)
                  }
                }
                .class("menu-group-list")
                .role(.group)
                .ariaLabelledby(group.title)
              }
              .class("menu-group")
            }
          }

          // Individual menu items (not in groups)
          if !menuItems.isEmpty {
            for (offset, item) in menuItems.enumerated() {
              renderMenuItem(item, itemIndex: itemIndex + offset)
            }
          }

          // Footer item
          if let footerItem = footer {
            renderMenuItem(footerItem, itemIndex: allItems.count, isFooter: true)
          }
        }
        .class("menu-list")
        .role(multiselect ? .listbox : .listbox)
        .ariaMultiselectable(multiselect)
      }
      .class(menuClass)
      .setAttribute(data("expanded"), expanded)
      .style {
        selector("&") {
          position(.absolute)
          top(perc(100))
          insetInlineStart(0)
          insetInlineEnd(0)
          marginBlockStart(spacing4)
          backgroundColor(backgroundColorBase)
          border(borderWidthBase, .solid, borderColorSubtle)
          borderRadius(borderRadiusBase)
          boxShadow(boxShadowMedium)
          zIndex(100)
          minWidth(minWidthMedium)
          maxWidth(maxWidthBase)
          boxSizing(.borderBox)
        }
        selector("&.menu-has-visible-limit") { overflowY(.auto) }
        descendant(".menu-list") {
          listStyle(.none)
          margin(0)
          padding(0)
        }
        if hasVisibleLimit, let visibleItemLimit {
          selector("&.menu-visible-limit-\(visibleItemLimit) .menu-list") {
            maxHeight(calc(visibleItemLimit * minSizeInteractivePointer))
            overflowY(.auto)
          }
        }
        selector("& .menu-group", "& .menu-group-list") {
          listStyle(.none)
          margin(0)
          padding(0)
        }
        selector("& .menu-group-header[data-title-hidden='false']") {
          display(.flex)
          alignItems(.center)
          gap(spacing8)
          padding(spacing12, spacing12, spacing4, spacing12)
        }
        descendant(".menu-group-title") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeSmall14)
          fontWeight(fontWeightBold)
          lineHeight(lineHeightSmall22)
          color(colorSubtle)
          margin(0)
        }
        descendant(".menu-group-title[data-hidden='true']") {
          position(.absolute)
          width(px(1))
          height(px(1))
          margin(px(-1))
          padding(0)
          overflow(.hidden)
          clip(rect(0, 0, 0, 0))
          whiteSpace(.nowrap)
          borderWidth(0)
        }
        descendant(".menu-group-description") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeXSmall12)
          lineHeight(lineHeightSmall22)
          color(colorSubtle)
          margin(0)
        }
        descendant(".menu-group-divider") {
          height(borderWidthBase)
          backgroundColor(borderColorSubtle)
          margin(spacing8, spacing0)
          border(.none)
        }
        descendant(".menu-pending") { padding(spacing12) }
        descendant(".menu-pending-content") {
          marginBlockStart(spacing8)
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightSmall22)
          color(colorSubtle)
        }
        descendant(".menu-no-results") {
          padding(spacing12)
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightSmall22)
          color(colorSubtle)
          textAlign(.center)
        }
        selector("&[data-expanded='false']") { display(.none).important() }
      }
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

  private class MenuInstance: @unchecked Sendable {
    private var menu: DOM.Element
    private var menuItems: [DOM.Element] = []
    private var highlightedIndex: Int = -1
    private var multiselect: Bool = false

    init(menu: DOM.Element) {
      self.menu = menu

      // Get multiselect state
      if let list = menu.querySelector(".menu-list") {
        if let ariaMulti = list.getAttribute("aria-multiselectable") {
          multiselect = stringEquals(ariaMulti, "true")
        }
      }

      // Get all menu items (MenuItemView instances)
      let items = menu.querySelectorAll(".menu-item-view:not(.menu-footer-item)")
      for item in items {
        menuItems.append(item)
      }

      bindEvents()
    }

    private func bindEvents() {
      // Listen for menu-item-change events from MenuItemView
      for (index, item) in menuItems.enumerated() {
        _ = item.addEventListener("menu-item-change") { [self] (event: Event) in
          let value = event.detail

          // Get current selection state
          let isSelected = stringEquals(item.getAttribute("aria-selected") ?? "", "true")
          let newSelected = !isSelected

          if self.multiselect {
            // Multiselect: toggle this item
            item.setAttribute(.ariaSelected, newSelected)
          } else {
            // Single select: deselect all, select this one
            for otherItem in self.menuItems {
              otherItem.setAttribute(.ariaSelected, false)
            }
            item.setAttribute(.ariaSelected, true)

            // Close menu
            self.menu.setAttribute(data("expanded"), false)
          }

          // Dispatch selection event from menu
          let menuEvent = CustomEvent(type: "menu-item-select", detail: value)
          self.menu.dispatchEvent(menuEvent)
        }

        // Listen for highlight events
        _ = item.addEventListener("menu-item-highlight") { [self] (event: Event) in
          self.highlightedIndex = index
          self.updateHighlight()
        }
      }

      // Scroll event for load-more
      if let list = menu.querySelector(".menu-list") {
        _ = list.addEventListener(.scroll) { [self] (event: Event) in
          let scrollTop = list.scrollTop
          let scrollHeight = list.scrollHeight
          let clientHeight = list.offsetHeight  // Using offsetHeight as a proxy for clientHeight if not available

          // Near bottom (within 50px)
          if scrollTop + clientHeight >= scrollHeight - 50 {
            let event = CustomEvent(type: "menu-load-more", detail: "")
            self.menu.dispatchEvent(event)
          }
        }
      }
    }

    public func handleKeydown(_ key: String) -> Bool {
      guard !menuItems.isEmpty else { return false }

      switch key {
      case "ArrowDown":
        highlightedIndex = min(highlightedIndex + 1, menuItems.count - 1)
        updateHighlight()
        scrollToHighlighted()
        return true

      case "ArrowUp":
        highlightedIndex = max(highlightedIndex - 1, 0)
        updateHighlight()
        scrollToHighlighted()
        return true

      case "Home":
        highlightedIndex = 0
        updateHighlight()
        scrollToHighlighted()
        return true

      case "End":
        highlightedIndex = menuItems.count - 1
        updateHighlight()
        scrollToHighlighted()
        return true

      case "Enter":
        if highlightedIndex >= 0 && highlightedIndex < menuItems.count {
          let item = menuItems[highlightedIndex]
          // Trigger click on MenuItemView
          item.click()
        }
        return true

      case "Escape":
        menu.setAttribute(data("expanded"), false)
        return true

      default:
        return false
      }
    }

    private func updateHighlight() {
      for (index, item) in menuItems.enumerated() {
        if index == highlightedIndex {
          item.setAttribute(data("highlighted"), true)

          // Dispatch keyboard navigation event
          let event = CustomEvent(type: "menu-item-keyboard-nav", detail: "")
          menu.dispatchEvent(event)
        } else {
          item.dataset["highlighted"] = "false"
        }
      }
    }

    private func scrollToHighlighted() {
      guard highlightedIndex >= 0 && highlightedIndex < menuItems.count else { return }
      let item = menuItems[highlightedIndex]

      // Scroll into view if needed
      item.scrollIntoView(
        .init(block: CSSOM.ScrollIntoViewOptions.nearest, inline: CSSOM.ScrollIntoViewOptions.nearest))
    }

    public func getHighlightedMenuItem() -> DOM.Element? {
      guard highlightedIndex >= 0 && highlightedIndex < menuItems.count else { return nil }
      return menuItems[highlightedIndex]
    }
  }

  public class MenuHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: MenuHydration?
    private var instances: [MenuInstance] = []

    public init() {
      hydrateAllMenus()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".menu-view") != nil else { return }
      instance = MenuHydration()
    }

    /// The menus a fragment brought in after the page was hydrated, and only
    /// those: every menu inside `root`, which must be new to the page.
    public static func hydrate(in root: DOM.Element) {
      for menu in root.querySelectorAll(".menu-view") {
        fragments.append(MenuInstance(menu: menu))
      }
    }
    private static nonisolated(unsafe) var fragments: [MenuInstance] = []

    private func hydrateAllMenus() {
      let allMenus = document.querySelectorAll(".menu-view")

      for menu in allMenus {
        let instance = MenuInstance(menu: menu)
        instances.append(instance)
      }
    }
  }
#endif
