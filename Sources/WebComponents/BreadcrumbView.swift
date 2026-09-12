#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A list of links to the parent pages of the current page in hierarchical order.
  public struct BreadcrumbView: HTMLContent {
    let items: [BreadcrumbItem]
    let truncateLength: Int
    let maxVisible: Int
    let `class`: String

    public struct BreadcrumbItem: Sendable {
      public let text: String?
      public let label: DOM.Node?
      public let url: String?

      public init(text: String? = nil, label: DOM.Node? = nil, url: String? = nil) {
        self.text = text
        self.label = label
        self.url = url
      }
    }

    public init(
      items: [BreadcrumbItem],
      truncateLength: Int = 40,
      maxVisible: Int = 6,
      class: String = ""
    ) {
      self.items = items
      self.truncateLength = truncateLength
      self.maxVisible = maxVisible
      self.`class` = `class`
    }

    public func build() -> DOM.Node {
      let visibleItems: [BreadcrumbItem]
      let overflowItems: [BreadcrumbItem]

      if items.count > maxVisible {
        visibleItems = [items[0]] + items.suffix(maxVisible - 1)
        overflowItems = Array(items[1..<(items.count - (maxVisible - 1))])
      } else {
        visibleItems = items
        overflowItems = []
      }

      let truncateText: (String) -> String = { text in
        if text.count > truncateLength {
          return String(text.prefix(truncateLength)) + "…"
        }
        return text
      }

      return nav {
        ol {
          for (index, item) in visibleItems.enumerated() {
            li {
              if index == 0 && !overflowItems.isEmpty {
                // First item
                if let url = item.url {
                  LinkView(url: url, class: "breadcrumb-link", title: item.text) {
                    item.label ?? DOM.Text(truncateText(item.text ?? ""))
                  }
                } else {
                  span { item.label ?? DOM.Text(truncateText(item.text ?? "")) }
                    .title(item.text ?? "")
                    .class("breadcrumb-current")
                }

                div {
                  NextIconView(width: px(8), height: px(8))
                }
                .class("breadcrumb-separator")
                .ariaHidden(true)

                // Overflow menu
                span {
                  MenuButtonView(
                    buttonLabel: "…",
                    menuItems: overflowItems.map { overflowItem in
                      MenuButtonView.MenuItem(
                        value: overflowItem.url ?? "",
                        label: overflowItem.text ?? ""
                      )
                    }
                  )
                }
                .class("breadcrumb-overflow")
              } else {
                // Regular item or current page
                let isLast = index == visibleItems.count - 1

                if isLast {
                  span { item.label ?? DOM.Text(truncateText(item.text ?? "")) }
                    .title(item.text ?? "")
                    .class("breadcrumb-current")
                    .ariaCurrent(.page)
                } else {
                  if let url = item.url {
                    LinkView(url: url, class: "breadcrumb-link", title: item.text) {
                      item.label ?? DOM.Text(truncateText(item.text ?? ""))
                    }
                  } else {
                    span { item.label ?? DOM.Text(truncateText(item.text ?? "")) }
                      .title(item.text ?? "")
                      .class("breadcrumb-current")
                  }
                }

                if !isLast {
                  div {
                    NextIconView(width: px(8), height: px(8))
                  }
                  .class("breadcrumb-separator")
                  .ariaHidden(true)
                }
              }
            }
            .class("breadcrumb-item")
          }
        }
        .class("breadcrumb-list")
      }
      .class(`class`.isEmpty ? "breadcrumb-view" : "breadcrumb-view \(`class`)")
      .ariaLabel("Breadcrumb")
      .style {
        selector("&") {
          display(.flex)
          alignItems(.center)
          flexWrap(.wrap)
          gap(spacing4)
          fontFamily(typographyFontSans)
          fontSize(fontSizeSmall14)
          lineHeight(1.618)
          color(colorSubtle)
        }
        // Inline flow, not flex: the trail fills each line and wraps wherever
        // it runs out — between crumbs or inside a long label — as running
        // text does. As a row of shrinkable flex items, all the give landed on
        // the one label with a space in it, folding "Mission Control" while
        // the bar still had room; as wrapping flex items, a whole crumb jumped
        // to the next line while the first could still hold half of it.
        descendant(".breadcrumb-list") {
          display(.block)
          listStyle(.none)
          margin(0)
          padding(0)
        }
        descendant(".breadcrumb-item") {
          display(.inline)
        }
        descendant(".breadcrumb-link") {
          display(.inline).important()
        }
        descendant(".breadcrumb-current") {
          color(colorBase)
          fontWeight(fontWeightNormal)
        }
        descendant(".breadcrumb-separator") {
          color(colorSubtle)
          userSelect(.none)
          display(.inlineFlex)
          alignItems(.center)
          justifyContent(.center)
          verticalAlign(.middle)
          marginInline(spacing4)
          lineHeight(1.618)
        }
        descendant(".breadcrumb-overflow") {
          display(.inlineFlex)
          alignItems(.center)
          gap(spacing4)
        }
      }
    }
  }
#endif
