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
          size: .medium,
          ariaLabel: "Open menu",
          class: "navbar-sidebar-btn sidebar-menu-btn",
          data: [("sidebar-menu", "true")]
        )
      }
      .class(`class`.isEmpty ? "sidebar-menu-button-view" : "sidebar-menu-button-view \(`class`)")
      .data("sidebar-menu", true)
      .data("visible", show)
      .ariaExpanded(false)
      .ariaControls("navbar-slide-menu")
      .style {
        selector("&") { display(.none) }
        selector("&[data-visible='true']") { display(.flex) }
      }
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes

  /// Owns the sidebar control itself, so desktop collapsing remains available
  /// even when a page has no other navbar interaction to hydrate.
  public final class SidebarMenuButtonHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: SidebarMenuButtonHydration?

    private let button: DOM.Element

    public static func hydrateIfPresent() {
      guard document.querySelector(".sidebar-menu-btn") != nil else { return }
      instance = SidebarMenuButtonHydration()
    }

    private init?() {
      guard let button = document.querySelector(".sidebar-menu-btn") else { return nil }
      self.button = button

      _ = button.addEventListener(.click) { [self] (event: Event) in
        event.preventDefault()
        // `minWidthBreakpointDesktop`, the width SidebarView shows from.
        // matchMedia takes a StaticString, so the token's value is spelled out.
        if window.matchMedia("(min-width: 1025px)") {
          toggleDesktopSidebar()
        } else {
          toggleSlideMenu()
        }
      }
    }

    private func toggleDesktopSidebar() {
      guard let sidebar = document.querySelector(".sidebar-view") else { return }
      let collapsed = sidebar.classList.contains("sidebar-collapsed")
      if collapsed {
        sidebar.classList.remove("sidebar-collapsed")
        button.classList.remove("sidebar-btn-collapsed")
        document.setCookie(name: "gnorium-sidebar-collapsed", value: "false", maxAge: 31_536_000)
      } else {
        sidebar.classList.add("sidebar-collapsed")
        button.classList.add("sidebar-btn-collapsed")
        document.setCookie(name: "gnorium-sidebar-collapsed", value: "true", maxAge: 31_536_000)
      }
    }

    private func toggleSlideMenu() {
      guard let slideWrapper = document.querySelector(".navbar-slide-wrapper") else { return }
      let isOpen = stringEquals(slideWrapper.dataset["state"] ?? "closed", "open")
      let slideMenu = document.querySelector("#navbar-slide-menu")
      button.setAttribute(.ariaExpanded, !isOpen)
      slideMenu?.setAttribute(.ariaHidden, isOpen)
      _ = slideWrapper.dataset["state"] = isOpen ? "closed" : "open"
      _ = document.body.dataset["navbarOverlayOpen"] = isOpen ? "false" : "true"
    }
  }
#endif
