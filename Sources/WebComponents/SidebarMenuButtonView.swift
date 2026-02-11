#if !os(WASI)

import CSSBuilder
import DesignTokens
import HTMLBuilder
import WebTypes

/// A sidebar menu button that toggles the slide-from-left sidebar panel.
public struct SidebarMenuButtonView: HTMLProtocol {
	let `class`: String

	public init(class: String = "") {
		self.class = `class`
	}

	public func render(indent: Int = 0) -> String {
		div {
			ButtonView(
				icon: IconView(icon: { size in
					MenuIconView(width: size, height: size)
				}, size: .medium),
				weight: .plain,
				size: .large,
				ariaLabel: "Open menu",
				class: "sidebar-menu-btn"
			)
		}
		.class(`class`.isEmpty ? "sidebar-menu-button-view" : "sidebar-menu-button-view \(`class`)")
		.data("sidebar-menu", true)
		.ariaExpanded(false)
		.ariaControls("navbar-slide-menu")
		.render(indent: indent)
	}
}

#endif
