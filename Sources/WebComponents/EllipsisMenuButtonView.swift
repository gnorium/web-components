#if !os(WASI)

import CSSBuilder
import DesignTokens
import HTMLBuilder
import WebTypes

/// A button that toggles an ellipsis popover menu.
public struct EllipsisMenuButtonView: HTMLProtocol {
	let `class`: String

	public init(class: String = "") {
		self.class = `class`
	}

	public func render(indent: Int = 0) -> String {
		div {
			ButtonView(
				icon: IconView(icon: { size in
					EllipsisIconView(width: size, height: size)
				}, size: .medium),
				weight: .quiet,
				size: .large,
				ariaLabel: "Settings",
				class: "navbar-ellipsis-btn"
			)
		}
		.class(`class`.isEmpty ? "ellipsis-menu-button-view" : "ellipsis-menu-button-view \(`class`)")
		.data("navbar-ellipsis", true)
		.ariaExpanded(false)
		.ariaControls("navbar-ellipsis-menu")
		.style {
			position(.relative)
		}
		.render(indent: indent)
	}
}

#endif
