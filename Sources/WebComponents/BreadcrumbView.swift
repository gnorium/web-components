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
      class: String = ""
    ) {
      self.items = items
      self.`class` = `class`
    }

    public func build() -> DOM.Node {
      return nav {
        ol {
          for (index, item) in items.enumerated() {
            let isLast = index == items.count - 1
            li {
              // Keep every ancestor visible; long labels expand within the trail.
              if isLast {
                span { item.label ?? DOM.Text(item.text ?? "") }
                  .title(item.text ?? "")
                  .class("breadcrumb-current")
                  .ariaCurrent(.page)
              } else if let url = item.url {
                LinkView(url: url, class: "breadcrumb-link", title: item.text) {
                  span { item.label ?? DOM.Text(item.text ?? "") }
                    .class("breadcrumb-label")
                    .data("edge-fade", "expand")
                }
              } else {
                span { item.label ?? DOM.Text(item.text ?? "") }
                  .title(item.text ?? "")
                  .class("breadcrumb-current")
              }

              if !isLast {
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
          gap(spacing8)
          fontFamily(typographyFontSans)
          fontSize(fontSizeSmall14)
          lineHeight(lineHeightContent)
          color(colorSubtle)
          // The width of where it is put, in a flex row as in a block: sized
          // to its content, the trail left no room for the page's own crumb
          // (which asks for none, and takes what is left) and wrapped it; and
          // never wider, or a long label would carry the trail off the page.
          flex("1 1 auto")
          minWidth(0)
          overflowX(.auto)
        }
        // Wrap between crumbs without hiding any ancestors in a menu.
        descendant(".breadcrumb-list") {
          display(.flex)
          flexWrap(.wrap)
          alignItems(.center)
          gap(spacing8)
          flex(1)
          listStyle(.none)
          margin(0)
          padding(0)
          minWidth(0)
        }
        descendant(".breadcrumb-item:has([data-edge-fade-expanded='true'])") {
          flexShrink(0)
          maxWidth(.none)
        }
        descendant(".breadcrumb-item") {
          display(.flex)
          alignItems(.center)
          gap(spacing8)
          flex("0 1 auto")
          maxWidth(perc(100))
          minWidth(0)
        }
        descendant(".breadcrumb-link") {
          display(.flex).important()
          minWidth(0)
        }
        descendant(".breadcrumb-current") {
          color(colorBase)
          fontWeight(fontWeightNormal)
        }
        selector("& .breadcrumb-current", "& .breadcrumb-label") {
          display(.block)
          minWidth(0)
          maxWidth(perc(100))
        }
        descendant(".breadcrumb-label") {
          maxWidth(px(240))
        }
        fadeOverflow("& .breadcrumb-label")
        descendant(".breadcrumb-label[data-edge-fade-expanded='true']") {
          whiteSpace(.nowrap).important()
          width(.maxContent)
          maxWidth(.none)
          overflow(.visible)
        }
        descendant(".breadcrumb-current") {
          whiteSpace(.normal)
          overflowWrap(.anywhere)
        }
        descendant(".breadcrumb-separator") {
          flexShrink(0)
        }
      }
    }
  }
#endif
