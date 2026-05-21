#if SERVER
  import CSSBuilder
  import CSSOMBuilder
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
      public let label: Node?
      public let url: String?

      public init(text: String? = nil, label: Node? = nil, url: String? = nil) {
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

    public func build() -> Node {
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
                  a { item.label ?? Text(truncateText(item.text ?? "")) }
                    .href(url)
                    .title(item.text ?? "")
                    .class("breadcrumb-link")
                    .style {
                      breadcrumbLinkCSS()
                    }
                } else {
                  span { item.label ?? Text(truncateText(item.text ?? "")) }
                    .title(item.text ?? "")
                    .class("breadcrumb-current")
                    .style {
                      breadcrumbCurrentCSS()
                    }
                }

                div {
                  NextIconView(width: px(8), height: px(8))
                }
                .class("breadcrumb-separator")
                .ariaHidden(true)
                .style {
                  breadcrumbSeparatorCSS()
                }

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
                .style {
                  breadcrumbOverflowCSS()
                }
              } else {
                // Regular item or current page
                let isLast = index == visibleItems.count - 1

                if isLast {
                  span { item.label ?? Text(truncateText(item.text ?? "")) }
                    .title(item.text ?? "")
                    .class("breadcrumb-current")
                    .ariaCurrent(.page)
                    .style {
                      breadcrumbCurrentCSS()
                    }
                } else {
                  if let url = item.url {
                    a { item.label ?? Text(truncateText(item.text ?? "")) }
                      .href(url)
                      .title(item.text ?? "")
                      .class("breadcrumb-link")
                      .style {
                        breadcrumbLinkCSS()
                      }
                  } else {
                    span { item.label ?? Text(truncateText(item.text ?? "")) }
                      .title(item.text ?? "")
                      .class("breadcrumb-current")
                      .style {
                        breadcrumbCurrentCSS()
                      }
                  }
                }

                if !isLast {
                  div {
                    NextIconView(width: px(8), height: px(8))
                  }
                  .class("breadcrumb-separator")
                  .ariaHidden(true)
                  .style {
                    breadcrumbSeparatorCSS()
                  }
                }
              }
            }
            .class("breadcrumb-item")
            .style {
              breadcrumbItemCSS()
            }
          }
        }
        .class("breadcrumb-list")
        .style {
          display(.flex)
          alignItems(.center)
          gap(spacing4)
          listStyle(.none)
          margin(0)
          padding(0)
        }
      }
      .class(`class`.isEmpty ? "breadcrumb-view" : "breadcrumb-view \(`class`)")
      .ariaLabel("Breadcrumb")
      .style {
        breadcrumbViewCSS()
      }
    }

    @CSSBuilder
    private func breadcrumbViewCSS() -> [CSSRule] {
      display(.flex)
      alignItems(.center)
      flexWrap(.wrap)
      gap(spacing4)
      fontFamily(typographyFontSans)
      fontSize(fontSizeSmall14)
      lineHeight(1.618)
      color(colorSubtle)
    }

    @CSSBuilder
    private func breadcrumbItemCSS() -> [CSSRule] {
      display(.flex)
      alignItems(.center)
      gap(spacing4)
    }

    @CSSBuilder
    private func breadcrumbLinkCSS() -> [CSSRule] {
      color(colorBlue)
      textDecoration(.none)
      maxWidth(px(350))
      overflowX(.hidden)
      textOverflow(.ellipsis)
      whiteSpace(.nowrap)
      transform(translateY(px(-1)))

      pseudoClass(.hover) {
        textDecoration(.underline).important()
      }

      pseudoClass(.focus) {
        outline(borderWidthThick, .solid, borderColorBlue).important()
        outlineOffset(px(1)).important()
        borderRadius(borderRadiusBase).important()
      }
    }

    @CSSBuilder
    private func breadcrumbCurrentCSS() -> [CSSRule] {
      color(colorBase)
      fontWeight(fontWeightNormal)
      maxWidth(px(350))
      overflowX(.hidden)
      textOverflow(.ellipsis)
      whiteSpace(.nowrap)
      transform(translateY(px(-1)))
    }

    @CSSBuilder
    private func breadcrumbSeparatorCSS() -> [CSSRule] {
      color(colorSubtle)
      userSelect(.none)
      display(.inlineFlex)
      alignItems(.center)
      justifyContent(.center)
      lineHeight(1.618) // Increased to 1.2 to prevent clipping
    }

    @CSSBuilder
    private func breadcrumbOverflowCSS() -> [CSSRule] {
      display(.inlineFlex)
      alignItems(.center)
      gap(spacing4)
    }
  }
#endif
