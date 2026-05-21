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
    let content: [Node]

    public init(
      class: String = "",
      navbarHeight: Int = 96,
      @HTMLBuilder content: () -> [Node]
    ) {
      self.class = `class`
      self.navbarHeight = navbarHeight
      self.content = content()
    }

    public func build() -> Node {
      div {
        // Backdrop with blur effect
        div {}
          .class("ellipsis-menu-backdrop")
          .data("ellipsis-menu-backdrop", "true")
          .style {
            ellipsisMenuBackdropCSS()
          }

        // Menu container — slides down from navbar
        div {
          ContainerView(size: .xLarge) {
            div {
              content
            }
            .style {
              display(.flex)
              flexDirection(.column)
              gap(spacing8)
            }
          }
        }
        .class("ellipsis-menu-container")
        .data("ellipsis-menu-container", "true")
        .style {
          ellipsisMenuContainerCSS()
        }
      }
      .id("navbar-ellipsis-menu")
      .class(`class`.isEmpty ? "ellipsis-menu-view" : "ellipsis-menu-view \(`class`)")
      .data("ellipsis-menu", "true")
      .ariaHidden(true)
      .style {
        ellipsisMenuViewCSS()
      }
    }

    // MARK: - CSS

    @CSSBuilder
    private func ellipsisMenuViewCSS() -> [CSSRule] {
      display(.none)
      position(.fixed)
      top(px(navbarHeight))
      insetInlineStart(0)
      width(perc(100))
      zIndex(zIndexOverlay)
      pointerEvents(.none)
    }

    @CSSBuilder
    private func ellipsisMenuBackdropCSS() -> [CSSRule] {
      position(.fixed)
      top(px(navbarHeight))
      insetInlineStart(0)
      width(perc(100))
      height(calc(vh(100) - px(navbarHeight)))
      backgroundColor(rgba(0, 0, 0, 0.4))
      backdropFilter(blur(rem(1)))
      webkitBackdropFilter(blur(rem(1)))
      opacity(0)
      transition(.opacity, transitionDurationMedium, transitionTimingFunctionSystem)
      zIndex(-1)
    }

    @CSSBuilder
    private func ellipsisMenuContainerCSS() -> [CSSRule] {
      position(.relative)
      width(perc(100))
      backgroundColor(backgroundColorBase)
      paddingBlockStart(spacing16)
      paddingBlockEnd(spacing16)
      borderBlockEnd(borderWidthBase, .solid, borderColorBase)

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

    // MARK: - Public Section Helpers

    @CSSBuilder
    public static func sectionCSS() -> [CSSRule] {
      display(.flex)
      flexDirection(.column)
      gap(spacing8)
    }

    @CSSBuilder
    public static func sectionHeaderCSS() -> [CSSRule] {
      fontFamily(typographyFontSans)
      fontSize(fontSizeXSmall12)
      fontWeight(fontWeightSemiBold)
      color(colorSubtle)
      letterSpacing(px(0.5))
    }

    @CSSBuilder
    public static func dividerCSS() -> [CSSRule] {
      height(px(1))
      backgroundColor(borderColorSubtle)
    }
  }
#endif
