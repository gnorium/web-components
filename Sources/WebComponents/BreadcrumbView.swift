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
        descendant(".breadcrumb-list") {
          display(.flex)
          alignItems(.center)
          gap(spacing4)
          listStyle(.none)
          margin(0)
          padding(0)
        }
        descendant(".breadcrumb-item") {
          display(.flex)
          alignItems(.center)
          gap(spacing4)
        }
        descendant(".breadcrumb-current") {
          color(colorBase)
          fontWeight(fontWeightNormal)
          maxWidth(px(350))
          overflowX(.hidden)
          textOverflow(.ellipsis)
          whiteSpace(.nowrap)
          transform(translateY(px(-1)))
        }
        descendant(".breadcrumb-separator") {
          color(colorSubtle)
          userSelect(.none)
          display(.inlineFlex)
          alignItems(.center)
          justifyContent(.center)
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
