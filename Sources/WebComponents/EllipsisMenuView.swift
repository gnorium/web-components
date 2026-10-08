#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Full-screen overlay menu triggered by EllipsisMenuButtonView: a
  /// `SheetView` below the navbar.
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
      // The sheet every full-screen menu is (`SheetView`): its backdrop,
      // its panel, its motion.
      SheetView(
        id: "navbar-ellipsis-menu",
        class: `class`.isEmpty ? "ellipsis-menu-view" : "ellipsis-menu-view \(`class`)",
        placement: .belowNavbar(height: navbarHeight)
      ) {
        ContainerView(size: .full) {
          div {
            content
          }
          .class("ellipsis-menu-content")
          .style {
            selector("&") {
              display(.flex)
              flexDirection(.column)
              gap(spacing8)
            }
          }
        }
      }
      .build()
    }
  }
#endif
