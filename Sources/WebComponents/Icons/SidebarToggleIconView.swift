#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct SidebarToggleIconView: HTMLProtocol {
	let `class`: String

	public init(class: String = "") {
		self.class = `class`
	}

	public func render(indent: Int = 0) -> String {
		span {
			span {}
			.class("sidebar-toggle-icon-line sidebar-toggle-icon-line-middle")
			.style {
				sidebarToggleIconLineCSS()
				top(perc(50))
				transform(translateY("-\(perc(50))"))
			}
		}
		.class(`class`.isEmpty ? "sidebar-toggle-icon-view" : "sidebar-toggle-icon-view \(`class`)")
		.style {
			position(.relative)
			display(.inlineBlock)
			width(px(20))
			height(px(16))
			cursor(.pointer)

			pseudoElement(.before) {
				content("\"\"")
				sidebarToggleIconLineCSS()
				top(0)
			}

			pseudoElement(.after) {
				content("\"\"")
				sidebarToggleIconLineCSS()
				bottom(0)
			}
		}
		.render(indent: indent)
	}
	
	@CSSBuilder
	private func sidebarToggleIconLineCSS() -> [CSSProtocol] {
		position(.absolute)
		width(perc(100))
		height(px(2))
		backgroundColor(.currentColor)
		transition(.all, s(0.2), .easeInOut)
		left(0)
        display(.block)
        borderRadius(px(1)) // Rounded caps for Apple-like look
	}
}

#endif
