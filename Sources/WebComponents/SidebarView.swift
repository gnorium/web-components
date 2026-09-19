#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Generic sidebar shell used by all layout sidebars.
  ///
  /// Owns all sidebar CSS: mobile-hide, desktop sticky viewport scrollport,
  /// collapse-animation transition, and the `.sidebar-collapsed` override rule
  /// (emitted globally so NavbarHydration's class-toggle works uniformly on any
  /// sidebar).
  public struct SidebarView: HTMLContent {
    let `class`: String
    let sidebarWidth: CSS.Length
    let collapsed: Bool
    let sidebarBody: DOM.Node

    public init(
      class: String,
      width: CSS.Length = px(256),
      collapsed: Bool = false,
      @HTMLBuilder content: () -> [DOM.Node]
    ) {
      self.class = `class`
      self.sidebarWidth = width
      self.collapsed = collapsed
      let nodes = content()
      self.sidebarBody = nodes.count == 1 ? nodes[0] : DOM.DocumentFragment(nodes)
    }

    public func build() -> DOM.Node {
      let baseClass = `class`.isEmpty ? "sidebar-view" : "sidebar-view \(`class`)"
      return aside {
        div {
          sidebarBody
        }
        .class("sidebar-content")
      }
      .data("sidebar", "true")
      .class(baseClass)
      .style {
        selector("&") {
          display(.none)

          // Desktop: stick to the viewport (ChatGPT-style). One scrollport on
          // `.sidebar-content` covers Mission Control → Sessions; nested lists
          // (e.g. sessions) expand fully inside it.
          media(minWidth(minWidthBreakpointTablet)) {
            display(.block)
            position(.sticky)
            top(0)
            alignSelf(.flexStart)
            width(sidebarWidth)
            minWidth(sidebarWidth)
            // Dynamic viewport units follow the usable browser viewport when
            // macOS accessibility text and browser chrome change its height.
            // The content remains the one scrollport for an enlarged sidebar.
            height(dvh(100))
            maxHeight(dvh(100))
            flexShrink(0)
            zIndex(zIndexSticky)
            backgroundColor(backgroundColorBase)
            borderInlineEnd(borderWidthBase, .solid, borderColorSubtle)
            overflow(.hidden)
            transition((.width, transitionDurationMedium, .ease), (.minWidth, transitionDurationMedium, .ease))
          }
        }

        descendant(".sidebar-content") {
          media(minWidth(minWidthBreakpointTablet)) {
            position(.absolute)
            top(0)
            right(0)
            bottom(0)
            left(0)
            width(perc(100))
            minWidth(0)
            display(.flex)
            flexDirection(.column)
            overflowX(.hidden)
            overflowY(.auto)
            paddingBlockStart(spacing16)
            // WebKit can exclude end padding from an overflowing flex
            // scrollport's scrollable area. A real flex item below the final
            // row keeps that breathing room reachable at large text sizes.
            paddingBlockEnd(0)
            paddingInlineStart(spacing0)
            paddingInlineEnd(spacing16)
            boxSizing(.borderBox)

            pseudoElement(.after) {
              content("\"\"")
              display(.block)
              height(spacing16)
              minHeight(spacing16)
              flexShrink(0)
            }
          }
        }

        selector("&.sidebar-collapsed") {
          media(minWidth(minWidthBreakpointTablet)) {
            width(0).important()
            minWidth(0).important()
            overflow(.hidden).important()
            borderInlineEnd(.none).important()
            padding(0).important()
          }

          nextSibling(".layout-content-area") {
            paddingInlineStart(spacing0).important()
          }
        }

        descendant(".sidebar-title") {
          whiteSpace(.nowrap)
        }

        descendant("li:first-child .sidebar-title") {
          media(minWidth(minWidthBreakpointTablet)) {
            paddingBlockStart(0).important()
          }
        }

        descendant("ul") {
          gap(spacing16)
        }

        descendant("li[aria-hidden=\"true\"]") {
          marginBlockStart(spacing4)
          marginBlockEnd(spacing4)
          // Bleed into sidebar-content inline-end padding so the rule
          // meets the sidebar’s vertical border.
          marginInlineEnd(calc(spacing0 - spacing16))
          maxWidth(.none)
        }

        // Comma group (not multi-arg `descendant`, which nests selectors).
        descendant(
          ".mission-control-sidebar-separator, .sidebar-section-divider, .admin-sidebar-divider"
        ) {
          marginInlineEnd(calc(spacing0 - spacing16))
          maxWidth(.none)
        }
      }
      .class(collapsed ? "\(baseClass) sidebar-collapsed" : baseClass)
    }
  }
#endif
