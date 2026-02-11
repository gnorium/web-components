#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A Tab is one of the selectable items included within Tabs.
/// Must be used with Tabs component - this component is only meant to be used inside TabsView.
public struct TabView: HTMLProtocol, Sendable {
	public let name: String
	public let label: String
	public let disabled: Bool
	public let url: String?
	public let content: [HTMLProtocol]
	let `class`: String

	public init(
		name: String,
		label: String = "",
		disabled: Bool = false,
		url: String? = nil,
		class: String = "",
		@HTMLBuilder content: () -> [HTMLProtocol]
	) {
		self.name = name
		self.label = label.isEmpty ? name : label
		self.disabled = disabled
		self.url = url
		self.content = content()
		self.`class` = `class`
	}

	@CSSBuilder
	private func tabButtonCSS(_ isActive: Bool, _ disabled: Bool, _ framed: Bool) -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		minWidth(px(64))
		padding(spacing12, spacing16)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightNormal)
		lineHeight(lineHeightSmall22)
		whiteSpace(.nowrap)
		textAlign(.center)
		backgroundColor(.transparent)
		border(.none)
		cursor(disabled ? cursorBaseDisabled : cursorBaseHover)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		position(.relative)

		if isActive {
			color(colorBlue)
			fontWeight(fontWeightBold)

			if !framed {
				borderBlockEnd(borderWidthThick, .solid, borderColorBlue)
			} else {
				backgroundColor(backgroundColorBase)
			}
		} else {
			color(colorBase)
			borderBlockEnd(borderWidthThick, .solid, borderColorTransparent)
		}

		if disabled {
			color(colorDisabled)
			cursor(cursorBaseDisabled)
		}

		if !disabled && !isActive {
			pseudoClass(.hover) {
				color(colorBlue).important()
				backgroundColor(backgroundColorBlueSubtle).important()
			}

			pseudoClass(.active) {
				backgroundColor(backgroundColorBlueSubtle).important()
			}
		}

		pseudoClass(.focus) {
			outline(borderWidthThick, .solid, borderColorBlue).important()
			outlineOffset(px(-2)).important()
		}
	}

	@CSSBuilder
	private func tabPanelCSS(_ framed: Bool) -> [CSSProtocol] {
		if framed {
			padding(spacing16)
		} else {
			padding(spacing16, 0)
		}
	}

	/// Renders the tab button (called by TabsView)
	public func renderButton(isActive: Bool, tabindex: Int, framed: Bool, indent: Int = 0) -> String {
		let displayLabel = label.isEmpty ? name : label

		return button { displayLabel }
		.type(.button)
		.class(`class`.isEmpty ? "tab-view" : "tab-view \(`class`)")
		.role("tab")
		.ariaSelected(isActive)
		.ariaControls("panel-\(name)")
		.id("tab-\(name)")
		.data("tab-name", name)
		.disabled(disabled)
		.tabindex(tabindex)
		.style {
			tabButtonCSS(isActive, disabled, framed)
		}
		.render(indent: indent)
	}

	/// Renders the tab panel content (called by TabsView)
	public func renderPanel(isActive: Bool, framed: Bool, indent: Int = 0) -> String {
		return section {
			content
		}
		.class("tab-panel")
		.role("tabpanel")
		.id("panel-\(name)")
		.ariaLabelledby("tab-\(name)")
		.tabindex(0)
		.hidden(!isActive)
		.style {
			tabPanelCSS(framed)
		}
		.render(indent: indent)
	}

	public func render(indent: Int = 0) -> String {
		// TabView should not be rendered directly - use TabsView
		return ""
	}
}

#endif
