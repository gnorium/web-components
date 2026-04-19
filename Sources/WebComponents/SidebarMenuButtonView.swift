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

	public init(class: String = "") {
		self.class = `class`
	}

	public func render() -> DOMNode {
		div {
			ButtonView(
				icon: IconView(icon: { size in
					MenuIconView(width: size, height: size)
				}, size: .medium),
				weight: .quiet,
				size: .large,
				ariaLabel: "Open menu",
				class: "sidebar-menu-btn"
			)
		}
		.class(`class`.isEmpty ? "sidebar-menu-button-view" : "sidebar-menu-button-view \(`class`)")
		.data("sidebar-menu", true)
		.ariaExpanded(false)
		.ariaControls("navbar-slide-menu")
		.style {
			// Hidden by default — CLIENT shows via inline display:flex when sidebar exists
			display(.none)

			// On desktop the sidebar column is visible, so never show hamburger
			media(minWidth(minWidthBreakpointTablet)) {
				display(.none).important()
			}
		}
		.render()
	}
}

#endif
