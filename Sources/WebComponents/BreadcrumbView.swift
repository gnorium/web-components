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
    let labelLength: Int
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
      labelLength: Int = 40,
      maxVisible: Int = 6,
      class: String = ""
    ) {
      self.items = items
      self.labelLength = labelLength
      self.maxVisible = maxVisible
      self.`class` = `class`
    }

    public func build() -> DOM.Node {
      // Past `maxVisible`, the middle folds into the overflow menu: the
      // trail's first two crumbs stay (home, and the section it is in), and
      // so do the crumbs nearest the page, the page's own and its parents'.
      // What goes is the run between—the crumbs a reader least needs to
      // see to know where they are (`Gnorium › Lexico-records › … ›
      // compute and -er › Noun › Versions › Version …`).
      let folds = items.count > maxVisible
      let head = folds ? min(2, max(maxVisible - 1, 1)) : items.count
      let tail = folds ? max(maxVisible - head, 1) : 0
      let visibleItems = folds ? Array(items.prefix(head)) + Array(items.suffix(tail)) : items
      let overflowItems = folds ? Array(items[head..<(items.count - tail)]) : []

      return nav {
        ol {
          for (index, item) in visibleItems.enumerated() {
            let isLast = index == visibleItems.count - 1
            li {
              // A label is whole, and one longer than `labelLength` fades
              // out at its end (`fadeOverflow`); its title is all of it, and
              // on a phone a tap shows all of it (on a link, a tap in the
              // fade: the words are the link's).
              if isLast {
                span { item.label ?? DOM.Text(item.text ?? "") }
                  .title(item.text ?? "")
                  .class("breadcrumb-current")
                  .ariaCurrent(.page)
                  .data("edge-fade", "expand")
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
                  .data("edge-fade", "expand")
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
        }
        // A row of crumbs that wraps between crumbs, never inside one: each
        // crumb (its label, then its chevron) keeps its size while the line
        // has room. The page's own crumb, last, takes what the line has left
        // and shrinks into it, fading at its end, so a long title stays after
        // its chevron; it drops to a line of its own only when fewer than
        // ten characters would be left for it.
        // 8px each side of every separator (the item's gap before it, the
        // list's after it): the separator is tight, with no room of its own.
        descendant(".breadcrumb-list") {
          display(.flex)
          flexWrap(.wrap)
          alignItems(.center)
          columnGap(spacing8)
          flex(1)
          listStyle(.none)
          margin(0)
          padding(0)
          minWidth(0)
        }
        descendant(".breadcrumb-item") {
          display(.flex)
          alignItems(.center)
          gap(spacing8)
          flex("0 1 auto")
          minWidth(0)
        }
        descendant(".breadcrumb-item:last-child") {
          flex("1 1 0")
          minWidth(min(ch(10), CSS.LengthPercentage(perc(100))))
        }
        descendant(".breadcrumb-link") {
          display(.flex).important()
          minWidth(0)
        }
        descendant(".breadcrumb-current") {
          color(colorBase)
          fontWeight(fontWeightNormal)
        }
        // A label runs to `labelLength` characters, or its crumb's room, and
        // fades out past it. In `ch` alone, not `min(…, 100%)`: a percentage
        // counts for nothing when a crumb is sized to its content, so the
        // crumb took the whole title's width and left its label adrift in it.
        // The room is the flex items' to give (`min-width: 0` down the row).
        selector("& .breadcrumb-current", "& .breadcrumb-label") {
          display(.block)
          minWidth(0)
          maxWidth(ch(labelLength))
        }
        fadeOverflow("& .breadcrumb-current", "& .breadcrumb-label")
        // Shown whole, it wraps in its crumb's room.
        selector("& .breadcrumb-current[aria-expanded='true']", "& .breadcrumb-label[aria-expanded='true']") {
          maxWidth(.none)
        }
        descendant(".breadcrumb-separator") {
          flexShrink(0)
        }
        descendant(".breadcrumb-overflow") {
          display(.inlineFlex)
          alignItems(.center)
          gap(spacing8)
        }
      }
    }
  }
#endif
