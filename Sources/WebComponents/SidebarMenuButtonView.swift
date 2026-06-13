#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A sidebar menu button that toggles the slide-from-left sidebar panel.
  public struct SidebarMenuButtonView: HTMLContent {
    let `class`: String
    let show: Bool

    public init(class: String = "", show: Bool = false) {
      self.class = `class`
      self.show = show
    }

    public func build() -> DOM.Node {
      div {
        ButtonView(
          icon: IconView(
            icon: { size in
              MenuIconView(width: size, height: size)
            }, size: .medium),
          weight: .quiet,
          size: .large,
          ariaLabel: "Open menu",
          class: "navbar-sidebar-btn sidebar-menu-btn"
        )
      }
      .class(`class`.isEmpty ? "sidebar-menu-button-view" : "sidebar-menu-button-view \(`class`)")
      .data("sidebar-menu", true)
      .ariaExpanded(false)
      .ariaControls("navbar-slide-menu")
      .style {
        if show {
          display(.flex)
        } else {
          display(.none)
        }
      }
    }
  }
#endif
