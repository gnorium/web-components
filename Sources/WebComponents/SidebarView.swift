#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Generic sidebar shell used by all layout sidebars.
  ///
  /// Owns all sidebar CSS: mobile-hide, desktop-sticky, collapse-animation transition,
  /// and the `.sidebar-collapsed` override rule (emitted globally so NavbarHydration's
  /// class-toggle works uniformly on any sidebar).
  public struct SidebarView: HTMLContent {
    let `class`: String
    let sidebarWidth: CSS.Length
    let collapsed: Bool
    let content: DOM.Node

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
      self.content = nodes.count == 1 ? nodes[0] : DOM.DocumentFragment(nodes)
    }

    public func build() -> DOM.Node {
      let baseClass = `class`.isEmpty ? "sidebar-view" : "sidebar-view \(`class`)"
      return aside {
        content
      }
      .data("sidebar", "true")
      .class(baseClass)
      .style {
        // Mobile: hidden — content cloned into navbar slide menu by NavbarHydration
        display(.none)

        // Desktop: visible sticky sidebar column with collapse-animation transition
        media(minWidth(minWidthBreakpointTablet)) {
          display(.flex).important()
          flexDirection(.column)
          width(sidebarWidth)
          minWidth(sidebarWidth)
          position(.sticky)
          top(0)
          left(0)
          zIndex(zIndexSticky)
          backgroundColor(backgroundColorBase)
          borderInlineEnd(borderWidthBase, .solid, borderColorSubtle)
          overflowY(.auto)
          transition((.width, transitionDurationMedium, .ease), (.minWidth, transitionDurationMedium, .ease), (.opacity, transitionDurationMedium, .ease), (.border, transitionDurationMedium, .ease))
        }

        selector("[data-sidebar].sidebar-collapsed") {
          media(minWidth(minWidthBreakpointTablet)) {
            width(0).important()
            minWidth(0).important()
            opacity(0).important()
            overflow(.hidden).important()
            borderInlineEnd(.none).important()
            padding(0).important()
          }

          nextSibling(".layout-content-area") {
            paddingInlineStart(spacing0).important()
          }
        }

        selector("[data-sidebar-collapsed=\"true\"] [data-sidebar]") {
          media(minWidth(minWidthBreakpointTablet)) {
            width(0).important()
            minWidth(0).important()
            opacity(0).important()
            overflow(.hidden).important()
            borderInlineEnd(.none).important()
            padding(0).important()
          }
        }

        selector("[data-sidebar-collapsed=\"true\"] [data-sidebar] + .layout-content-area") {
          media(minWidth(minWidthBreakpointTablet)) {
            paddingInlineStart(spacing0).important()
          }
        }

        selector("[data-sidebar-collapsed=\"true\"] [data-sidebar]") {
          media(minWidth(minWidthBreakpointTablet)) {
            width(0).important()
            minWidth(0).important()
            opacity(0).important()
            overflow(.hidden).important()
            borderInlineEnd(.none).important()
            padding(0).important()
          }
        }

        selector("[data-sidebar-collapsed=\"true\"] [data-sidebar] + .layout-content-area") {
          media(minWidth(minWidthBreakpointTablet)) {
            paddingInlineStart(spacing0).important()
          }
        }

        descendant(".sidebar-title") {
          whiteSpace(.nowrap)
        }

        descendant("li:first-child .sidebar-title") {
          media(minWidth(minWidthBreakpointTablet)) {
            paddingBlockStart(spacing32).important()
          }
        }

        descendant("ul") {
          gap(spacing16)
        }

        descendant("li[aria-hidden=\"true\"]") {
          marginBlockStart(spacing4)
          marginBlockEnd(spacing4)
        }
      }
      .class(collapsed ? "\(baseClass) sidebar-collapsed" : baseClass)
    }
  }
#endif
