#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct SidebarToggleButtonView: HTMLProtocol {
	let `class`: String

	public init(class: String = "") {
		self.class = `class`
	}

	public func render(indent: Int = 0) -> String {
		button {
			SidebarToggleIconView()
		}
		.type(.button)
		.class(`class`.isEmpty ? "sidebar-toggle-button-view" : "sidebar-toggle-button-view \(`class`)")
		.ariaLabel("Toggle sidebar")
		.data("navbar-sidebar-toggle", true)
		.style {
			backgroundColor(.transparent)
			border(.none)
			cursor(.pointer)
			padding(0)
			display(.flex)
			alignItems(.center)
			justifyContent(.center)
			width(px(32))
			height(px(32))
			color(colorBase)
			transition(.all, s(0.2), .easeInOut)
			
			pseudoClass(.hover) {
				opacity(0.8)
			}
			
			media(minWidth(minWidthBreakpointTablet)) {
				display(.none).important()
			}
		}
		.render(indent: indent)
	}
}

#endif
