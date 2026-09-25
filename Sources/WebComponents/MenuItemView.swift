#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A MenuItem is a selectable option within a Menu.
  public struct MenuItemView: HTMLContent {
    let id: String
    let value: String
    let disabled: Bool
    let selected: Bool
    let active: Bool
    let highlighted: Bool
    let label: String
    let match: String
    let supportingText: String
    let url: String
    let urlNewTab: Bool
    let icon: String?
    let showThumbnail: Bool
    let thumbnail: Thumbnail?
    let description: String?
    let searchQuery: String
    let boldLabel: Bool
    let hideDescriptionOverflow: Bool
    let itemColor: MenuItemColor
    let multiselect: Bool
    let content: [DOM.Node]
    let `class`: String

    public struct Thumbnail: Sendable {
      let url: String
      let alt: String

      public init(url: String, alt: String = "") {
        self.url = url
        self.alt = alt
      }
    }

    /// Apple HIG color for the menu item
    public enum MenuItemColor: String, Sendable {
      case `default`
      case red

      // Legacy alias
      public static let destructive = MenuItemColor.red
    }

    /// Data structure for menu items
    public struct MenuItemData: Sendable {
      let value: String
      let label: String?
      let description: String?
      let icon: String?
      let thumbnail: String?
      let disabled: Bool

      public init(
        value: String,
        label: String? = nil,
        description: String? = nil,
        icon: String? = nil,
        thumbnail: String? = nil,
        disabled: Bool = false
      ) {
        self.value = value
        self.label = label
        self.description = description
        self.icon = icon
        self.thumbnail = thumbnail
        self.disabled = disabled
      }
    }

    public init(
      id: String,
      value: String,
      disabled: Bool = false,
      selected: Bool = false,
      active: Bool = false,
      highlighted: Bool = false,
      label: String = "",
      match: String = "",
      supportingText: String = "",
      url: String = "",
      urlNewTab: Bool = false,
      icon: String? = nil,
      showThumbnail: Bool = false,
      thumbnail: Thumbnail? = nil,
      description: String? = nil,
      searchQuery: String = "",
      boldLabel: Bool = false,
      hideDescriptionOverflow: Bool = false,
      action: MenuItemColor = .default,
      multiselect: Bool = false,
      class: String = "",
      @HTMLBuilder content: () -> [DOM.Node] = { [] }
    ) {
      self.id = id
      self.value = value
      self.disabled = disabled
      self.selected = selected
      self.active = active
      self.highlighted = highlighted
      self.label = label
      self.match = match
      self.supportingText = supportingText
      self.url = url
      self.urlNewTab = urlNewTab
      self.icon = icon
      self.showThumbnail = showThumbnail
      self.thumbnail = thumbnail
      self.description = description
      self.searchQuery = searchQuery
      self.boldLabel = boldLabel
      self.hideDescriptionOverflow = hideDescriptionOverflow
      self.itemColor = action
      self.multiselect = multiselect
      self.`class` = `class`
      self.content = content()
    }

    public func build() -> DOM.Node {
      let hasCustomContent = !content.isEmpty
      let displayLabel = label.isEmpty ? value : label
      let hasSearchQuery = !searchQuery.isEmpty
      let hasMatch = !match.isEmpty
      let hasSupportingText = !supportingText.isEmpty
      let hasDescription = description != nil && !(description ?? "").isEmpty
      let hasIcon = icon != nil
      let hasThumbnail = showThumbnail
      let hasUrl = !url.isEmpty

      @HTMLBuilder
      func renderLabelWithHighlight() -> [DOM.Node] {
        if hasSearchQuery && stringContainsCaseInsensitive(displayLabel, searchQuery) {
          let lowerLabel = stringLowercased(displayLabel)
          let lowerQuery = stringLowercased(searchQuery)

          if let idx = stringIndexOf(lowerLabel, lowerQuery) {
            let startIndex = idx
            let endIndex = idx + Array(lowerQuery.utf8).count

            let beforeQuery = stringSubstring(displayLabel, from: 0, to: startIndex)
            let queryText = stringSubstring(displayLabel, from: startIndex, to: endIndex)
            let afterQuery = stringSubstring(displayLabel, from: endIndex)

            span { beforeQuery }
              .class("menu-item-label")
            span { queryText }
              .class("menu-item-search-query")
            span { afterQuery }
              .class("menu-item-label")
          }
        } else {
          span { displayLabel }
            .class("menu-item-label")
        }
      }

      // Main content
      let itemContent: [DOM.Node] = {
        if hasCustomContent {
          return content
        }

        var items: [DOM.Node] = []

        // Multiselect checkbox
        if multiselect {
          items.append(
            span {
              if selected {
                span { CheckIconView() }
                  .class("menu-item-checkmark")
                  .ariaHidden(true)
              }
            }
            .class("menu-item-checkbox")
          )
        }

        // Thumbnail
        if hasThumbnail {
          if let thumb = thumbnail {
            items.append(
              span {
                img()
                  .src(thumb.url)
                  .alt(thumb.alt)
                  .class("menu-item-thumbnail-image")
              }
              .class("menu-item-thumbnail")
            )
          } else {
            items.append(
              span {
                span { icon ?? "📷" }
                  .class("menu-item-thumbnail-placeholder")
                  .ariaHidden(true)
              }
              .class("menu-item-thumbnail")
            )
          }
        }

        // Icon (only if not showing thumbnail)
        if hasIcon && !hasThumbnail {
          items.append(
            span { icon! }
              .class("menu-item-icon")
              .ariaHidden(true)
          )
        }

        // DOM.Text content
        items.append(
          span {
            // Title (label + match + supporting text)
            span {
              renderLabelWithHighlight()

              if hasMatch {
                span { " (\(match))" }
                  .class("menu-item-match")
              }

              if hasSupportingText {
                span { " \(supportingText)" }
                  .class("menu-item-supporting-text")
              }
            }
            .class("menu-item-title")

            // Description
            if hasDescription {
              span { description! }
                .class("menu-item-description")
            }
          }
          .class("menu-item-text")
        )

        return items
      }()

      // Wrapper element (a or li)
      if hasUrl {
        var link = a {
          itemContent
        }
        .href(url)
        .class(`class`.isEmpty ? "menu-item-view" : "menu-item-view \(`class`)")
        .id(id)
        .role(.option)
        .ariaSelected(selected)
        .ariaDisabled(disabled)
        .data("value", value)

        if highlighted {
          link = link.data("highlighted", "true")
        }

        if active {
          link = link.data("active", "true")
        }

        if urlNewTab {
          link = link.target(.blank).rel(.noopener)
        }

        return
          link
          .style {
            selector("&") {
              display(.flex)
              alignItems(.center)
              gap(spacing12)
              padding(spacing12, spacing16)
              minHeight(px(40))
              width(perc(100))
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              lineHeight(lineHeightSmall22)
              color(disabled ? colorDisabled : (itemColor == .red ? colorRed : colorSubtle))
              backgroundColor(backgroundColorTransparent)
              border(borderWidthBase, .solid, disabled ? borderColorDisabled : borderColorSubtle)
              borderRadius(borderRadiusBase)
              cursor(disabled ? cursorNotAllowed : cursorBase)
              userSelect(.none)
              textDecoration(.none)
              boxSizing(.borderBox)
              transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

              if highlighted && !disabled {
                color(colorBlue)
                border(borderWidthBase, .solid, borderColorBlue)
              }

              if active && !disabled {
                color(colorBlue)
                border(borderWidthBase, .solid, borderColorBlue)
              }

              if !disabled {
                pseudoClass(.hover) {
                  color(colorBlue).important()
                  border(borderWidthBase, .solid, borderColorBlue).important()
                  cursor(cursorBaseHover).important()
                }

                pseudoClass(.active) {
                  color(colorBlue).important()
                  border(borderWidthBase, .solid, borderColorBlue).important()
                  cursor(cursorBaseHover).important()
                }

                pseudoClass(.focus) {
                  color(colorBlueFocus).important()
                  outline(borderWidthBase, .solid, borderColorBlueFocus).important()
                  outlineOffset(px(-1)).important()
                }
              }
            }
            descendant(".menu-item-checkbox") {
              display(.inlineFlex)
              alignItems(.center)
              justifyContent(.center)
              width(sizeIconMedium)
              height(sizeIconMedium)
              flexShrink(0)
              border(borderWidthBase, .solid, borderColorInputBinary)
              borderRadius(borderRadiusBase)
              backgroundColor(selected ? backgroundColorInputBinaryChecked : backgroundColorBase)
              transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
            }
            descendant(".menu-item-checkmark") {
              display(.flex)
              width(sizeIconXSmall)
              height(sizeIconXSmall)
              color(colorInvertedFixed)
            }
            selector("& .menu-item-checkmark svg") {
              width(perc(100))
              height(perc(100))
            }
            descendant(".menu-item-thumbnail") {
              display(.inlineFlex)
              alignItems(.center)
              justifyContent(.center)
              width(px(40))
              height(px(40))
              flexShrink(0)
              borderRadius(borderRadiusBase)
              overflow(.hidden)
              backgroundColor(backgroundColorNeutralSubtle)
            }
            descendant(".menu-item-thumbnail-image") {
              width(perc(100))
              height(perc(100))
              objectFit(.cover)
            }
            descendant(".menu-item-thumbnail-placeholder") {
              fontSize(fontSizeLarge18)
              color(colorPlaceholder)
            }
            descendant(".menu-item-icon") {
              display(.inlineFlex)
              alignItems(.center)
              justifyContent(.center)
              width(sizeIconMedium)
              height(sizeIconMedium)
              flexShrink(0)
              color(colorSubtle)
              fontSize(fontSizeLarge18)
            }
            descendant(".menu-item-text") {
              display(.flex)
              flexDirection(.column)
              gap(spacing4)
              flex(1)
              minWidth(0)
            }
            descendant(".menu-item-title") {
              display(.flex)
              alignItems(.baseline)
              gap(spacing4)
              flexWrap(.wrap)
            }
            descendant(".menu-item-label") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              fontWeight(boldLabel || hasSearchQuery ? fontWeightBold : fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorBase)
              wordWrap(.breakWord)
            }
            descendant(".menu-item-search-query") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              fontWeight(fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorBase)
            }
            descendant(".menu-item-match") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              fontWeight(fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorSubtle)
            }
            descendant(".menu-item-supporting-text") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              fontWeight(fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorSubtle)
            }
            descendant(".menu-item-description") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeSmall14)
              fontWeight(fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorSubtle)
              if hideDescriptionOverflow {
                overflow(.hidden)
                textOverflow(.ellipsis)
                whiteSpace(.nowrap)
              }
            }
          }

      } else {
        var listItem = li {
          itemContent
        }
        .class(`class`.isEmpty ? "menu-item-view" : "menu-item-view \(`class`)")
        .id(id)
        .role(.option)
        .ariaSelected(selected)
        .ariaDisabled(disabled)
        .data("value", value)

        if highlighted {
          listItem = listItem.data("highlighted", "true")
        }

        if active {
          listItem = listItem.data("active", "true")
        }

        return
          listItem
          .style {
            selector("&") {
              display(.flex)
              alignItems(.center)
              gap(spacing12)
              padding(spacing12, spacing16)
              minHeight(px(40))
              width(perc(100))
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              lineHeight(lineHeightSmall22)
              color(disabled ? colorDisabled : (itemColor == .red ? colorRed : colorSubtle))
              backgroundColor(backgroundColorTransparent)
              border(borderWidthBase, .solid, disabled ? borderColorDisabled : borderColorSubtle)
              borderRadius(borderRadiusBase)
              cursor(disabled ? cursorNotAllowed : cursorBase)
              userSelect(.none)
              textDecoration(.none)
              boxSizing(.borderBox)
              transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

              if highlighted && !disabled {
                color(colorBlue)
                border(borderWidthBase, .solid, borderColorBlue)
              }

              if active && !disabled {
                color(colorBlue)
                border(borderWidthBase, .solid, borderColorBlue)
              }

              if !disabled {
                pseudoClass(.hover) {
                  color(colorBlue).important()
                  border(borderWidthBase, .solid, borderColorBlue).important()
                  cursor(cursorBaseHover).important()
                }

                pseudoClass(.active) {
                  color(colorBlue).important()
                  border(borderWidthBase, .solid, borderColorBlue).important()
                  cursor(cursorBaseHover).important()
                }

                pseudoClass(.focus) {
                  color(colorBlueFocus).important()
                  outline(borderWidthBase, .solid, borderColorBlueFocus).important()
                  outlineOffset(px(-1)).important()
                }
              }
            }
            descendant(".menu-item-checkbox") {
              display(.inlineFlex)
              alignItems(.center)
              justifyContent(.center)
              width(sizeIconMedium)
              height(sizeIconMedium)
              flexShrink(0)
              border(borderWidthBase, .solid, borderColorInputBinary)
              borderRadius(borderRadiusBase)
              backgroundColor(selected ? backgroundColorInputBinaryChecked : backgroundColorBase)
              transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
            }
            descendant(".menu-item-checkmark") {
              display(.flex)
              width(sizeIconXSmall)
              height(sizeIconXSmall)
              color(colorInvertedFixed)
            }
            selector("& .menu-item-checkmark svg") {
              width(perc(100))
              height(perc(100))
            }
            descendant(".menu-item-thumbnail") {
              display(.inlineFlex)
              alignItems(.center)
              justifyContent(.center)
              width(px(40))
              height(px(40))
              flexShrink(0)
              borderRadius(borderRadiusBase)
              overflow(.hidden)
              backgroundColor(backgroundColorNeutralSubtle)
            }
            descendant(".menu-item-thumbnail-image") {
              width(perc(100))
              height(perc(100))
              objectFit(.cover)
            }
            descendant(".menu-item-thumbnail-placeholder") {
              fontSize(fontSizeLarge18)
              color(colorPlaceholder)
            }
            descendant(".menu-item-icon") {
              display(.inlineFlex)
              alignItems(.center)
              justifyContent(.center)
              width(sizeIconMedium)
              height(sizeIconMedium)
              flexShrink(0)
              color(colorSubtle)
              fontSize(fontSizeLarge18)
            }
            descendant(".menu-item-text") {
              display(.flex)
              flexDirection(.column)
              gap(spacing4)
              flex(1)
              minWidth(0)
            }
            descendant(".menu-item-title") {
              display(.flex)
              alignItems(.baseline)
              gap(spacing4)
              flexWrap(.wrap)
            }
            descendant(".menu-item-label") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              fontWeight(boldLabel || hasSearchQuery ? fontWeightBold : fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorBase)
              wordWrap(.breakWord)
            }
            descendant(".menu-item-search-query") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              fontWeight(fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorBase)
            }
            descendant(".menu-item-match") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              fontWeight(fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorSubtle)
            }
            descendant(".menu-item-supporting-text") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              fontWeight(fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorSubtle)
            }
            descendant(".menu-item-description") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeSmall14)
              fontWeight(fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorSubtle)
              if hideDescriptionOverflow {
                overflow(.hidden)
                textOverflow(.ellipsis)
                whiteSpace(.nowrap)
              }
            }
          }

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

  private class MenuItemInstance: @unchecked Sendable {
    private var menuItem: DOM.Element

    init(menuItem: DOM.Element) {
      self.menuItem = menuItem

      bindEvents()
    }

    private func bindEvents() {
      // Click event
      _ = menuItem.addEventListener(.click) { [self] (event: Event) in
        // Check if disabled
        if stringEquals(self.menuItem.getAttribute("aria-disabled") ?? "", "true") {
          event.preventDefault()
          return
        }

        // Get value
        let value = self.menuItem.dataset["value"] ?? ""
        if stringEquals(value, "") { return }

        // Dispatch change event
        let customEvent = CustomEvent(type: "menu-item-change", detail: value)
        self.menuItem.dispatchEvent(customEvent)
      }

      // Mouse enter for highlighting
      _ = menuItem.addEventListener(.mouseenter) { [self] _ in
        self.menuItem.dataset["highlighted"] = "true"

        let event = CustomEvent(type: "menu-item-highlight", detail: "")
        self.menuItem.dispatchEvent(event)
      }

      // Mouse leave
      _ = menuItem.addEventListener(.mouseleave) { [self] _ in
        self.menuItem.dataset["highlighted"] = "false"
      }

      // Mouse down for active state
      _ = menuItem.addEventListener(.mousedown) { [self] _ in
        self.menuItem.dataset["active"] = "true"
      }

      // Mouse up
      _ = menuItem.addEventListener(.mouseup) { [self] _ in
        self.menuItem.dataset["active"] = "false"
      }
    }
  }

  public class MenuItemHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: MenuItemHydration?
    private var instances: [MenuItemInstance] = []

    public init() {
      hydrateAllMenuItems()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".menu-item-view") != nil else { return }
      instance = MenuItemHydration()
    }

    /// The items a fragment brought in after the page was hydrated, and
    /// only those: every item inside `root`, which must be new to the page.
    /// Before their menu's, which listens for what they dispatch.
    public static func hydrate(in root: DOM.Element) {
      for item in root.querySelectorAll(".menu-item-view") {
        fragments.append(MenuItemInstance(menuItem: item))
      }
    }
    private static nonisolated(unsafe) var fragments: [MenuItemInstance] = []

    private func hydrateAllMenuItems() {
      let allMenuItems = document.querySelectorAll(".menu-item-view")

      for menuItem in allMenuItems {
        let instance = MenuItemInstance(menuItem: menuItem)
        instances.append(instance)
      }
    }
  }
#endif
