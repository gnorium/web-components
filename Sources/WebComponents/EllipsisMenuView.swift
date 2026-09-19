#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Full-screen overlay menu triggered by EllipsisMenuButtonView.
  /// Renders a blurred backdrop + slide-down container below the navbar.
  /// Pass app-specific content (sections, toggles, links) via the content closure.
  public struct EllipsisMenuView: HTMLContent {
    let `class`: String
    let navbarHeight: Int
    let content: [DOM.Node]

    public init(
      class: String = "",
      navbarHeight: Int = 96,
      @HTMLBuilder content: () -> [DOM.Node]
    ) {
      self.class = `class`
      self.navbarHeight = navbarHeight
      self.content = content()
    }

    public func build() -> DOM.Node {
      div {
        // Backdrop with blur effect
        div {}
          .class("ellipsis-menu-backdrop")
          .data("ellipsis-menu-backdrop", "true")

        // Menu container — slides down from navbar
        div {
          ContainerView(size: .xLarge) {
            div {
              content
            }
            .class("ellipsis-menu-content")
          }
        }
        .class("ellipsis-menu-container")
        .data("ellipsis-menu-container", "true")
      }
      .id("navbar-ellipsis-menu")
      .class(`class`.isEmpty ? "ellipsis-menu-view" : "ellipsis-menu-view \(`class`)")
      .data("ellipsis-menu", "true")
      .data("state", "closed")
      .ariaHidden(true)
      .style {
        selector("&") {
          display(.none)
          position(.fixed)
          top(px(navbarHeight))
          insetInlineStart(0)
          width(perc(100))
          height(calc(dvh(100) - px(navbarHeight)))
          zIndex(zIndexOverlay)
          pointerEvents(.none)
        }
        descendant(".ellipsis-menu-backdrop") {
          position(.absolute)
          inset(0)
          backgroundColor(backgroundColorBackdropDark)
          backdropFilter(blur(rem(1)))
          webkitBackdropFilter(blur(rem(1)))
          opacity(0)
          transition(.opacity, transitionDurationMedium, transitionTimingFunctionSystem)
          zIndex(-1)
        }
        descendant(".ellipsis-menu-container") {
          position(.relative)
          width(perc(100))
          maxHeight(perc(100))
          backgroundColor(backgroundColorBase)
          paddingBlockStart(spacing16)
          paddingBlockEnd(spacing16)
          borderBlockEnd(borderWidthBase, .solid, borderColorBase)
          boxSizing(.borderBox)
          overflowY(.auto)
          opacity(0)
          transform(translateY(perc(-100)))
          transition(
            (.opacity, transitionDurationMedium, transitionTimingFunctionSystem),
            (.transform, transitionDurationMedium, transitionTimingFunctionSystem)
          )
          media(minWidth(minWidthBreakpointTablet)) {
            paddingBlockStart(spacing20)
            paddingBlockEnd(spacing20)
          }
        }
        descendant(".ellipsis-menu-content") {
          display(.flex)
          flexDirection(.column)
          gap(spacing8)
        }
        selector("&[data-state='opening']", "&[data-state='open']", "&[data-state='closing']") { display(.block) }
        selector("&[data-state='opening']", "&[data-state='open']") { pointerEvents(.auto) }
        descendant("[data-ellipsis-menu-backdrop='true']") {
          pointerEvents(.none)
          opacity(0)
        }
        descendant("[data-ellipsis-menu-container='true']") {
          opacity(0)
          transform(translateY(perc(-100)))
        }
        selector("&[data-state='open'] [data-ellipsis-menu-backdrop='true']") {
          opacity(1)
          pointerEvents(.auto)
        }
        selector("&[data-state='open'] [data-ellipsis-menu-container='true']") {
          opacity(1)
          transform(translateY(px(0)))
        }
      }
    }

  }
#endif
