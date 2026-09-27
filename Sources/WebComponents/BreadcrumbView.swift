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
      // Past `maxVisible`, the middle folds into the overflow menu: the
      // trail's first two crumbs stay (home, and the section it is in), and
      // so do the crumbs nearest the page, the page's own and its parents'.
      // What goes is the run between — the crumbs a reader least needs to
      // see to know where they are (`Gnorium › Lexico-records › … ›
      // compute and -er › Noun › Versions › Version …`).
      let folds = items.count > maxVisible
      let head = folds ? min(2, max(maxVisible - 1, 1)) : items.count
      let tail = folds ? max(maxVisible - head, 1) : 0
      let visibleItems = folds ? Array(items.prefix(head)) + Array(items.suffix(tail)) : items
      let overflowItems = folds ? Array(items[head..<(items.count - tail)]) : []

      let truncateText: (String) -> String = { text in
        if text.count > truncateLength {
          return String(text.prefix(truncateLength)) + "…"
        }
        return text
      }

      return nav {
        ol {
          for (index, item) in visibleItems.enumerated() {
            let isLast = index == visibleItems.count - 1
            li {
              if isLast {
                span { item.label ?? DOM.Text(truncateText(item.text ?? "")) }
                  .title(item.text ?? "")
                  .class("breadcrumb-current")
                  .ariaCurrent(.page)
              } else if let url = item.url {
                LinkView(url: url, class: "breadcrumb-link", title: item.text) {
                  item.label ?? DOM.Text(truncateText(item.text ?? ""))
                }
              } else {
                span { item.label ?? DOM.Text(truncateText(item.text ?? "")) }
                  .title(item.text ?? "")
                  .class("breadcrumb-current")
              }

              if !isLast {
                BreadcrumbSeparatorView(class: "breadcrumb-separator")
              }

              // The folded crumbs, after the head, where they stood.
              if index == head - 1 && !overflowItems.isEmpty {
                span {
                  MenuButtonView(
                    buttonLabel: "…",
                    // Links, as the crumbs they stand for: a folded crumb
                    // is still a way up.
                    menuItems: overflowItems.map { overflowItem in
                      MenuButtonView.MenuItem(
                        value: overflowItem.url ?? "",
                        label: overflowItem.text ?? "",
                        url: overflowItem.url
                      )
                    }
                  )
                }
                .class("breadcrumb-overflow")

                BreadcrumbSeparatorView(class: "breadcrumb-separator")
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
          lineHeight(lineHeightContent)
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
        // Its icon, size and colour are BreadcrumbSeparatorView's; in the
        // inline flow a margin is the only way to space it.
        descendant(".breadcrumb-separator") {
          marginInline(spacing4)
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
