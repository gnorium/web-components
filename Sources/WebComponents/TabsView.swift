#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Tabs consist of two or more tab items for navigating between different sections of content.
public struct TabsView: HTMLProtocol {
	let tabs: [TabView]
	let activeTab: String?
	let framed: Bool
	let variant: Variant
	let `class`: String

	/// Visual style variant for tab buttons
	public enum Variant: String, Sendable {
		/// Underline active tab, transparent background
		case quiet
		/// Pill-shaped tabs, filled background on active tab
		case solid
	}

	public init(
		tabs: [TabView],
		activeTab: String? = nil,
		framed: Bool = false,
		variant: Variant = .quiet,
		class: String = ""
	) {
		self.tabs = tabs
		self.activeTab = activeTab ?? tabs.first?.name
		self.framed = framed
		self.variant = variant
		self.`class` = `class`
	}

	@CSSBuilder
	private func tabsViewCSS(_ framed: Bool) -> [CSSProtocol] {
		display(.block)
		fontFamily(typographyFontSans)

		if framed {
			border(borderWidthBase, .solid, borderColorSubtle)
			borderRadius(borderRadiusBase)
		}
	}

	@CSSBuilder
	private func tabsHeaderCSS(_ variant: Variant) -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		position(.relative)
		overflow(.hidden)

		switch variant {
		case .quiet:
			gap(0)
		case .solid:
			gap(spacing4)
		}
	}

	@CSSBuilder
	private func tabsListCSS(_ variant: Variant) -> [CSSProtocol] {
		display(.flex)
		margin(0)
		padding(0)
		listStyle(.none)
		flexGrow(1)

		switch variant {
		case .quiet:
			gap(spacing4)
			overflow(.auto)
			scrollbarWidth(.none)

			pseudoElement(.webkitScrollbar) {
				display(.none).important()
			}
		case .solid:
			gap(spacing8)
			flexWrap(.wrap)
		}
	}

	@CSSBuilder
	private func tabButtonCSS(_ isActive: Bool, _ disabled: Bool, _ framed: Bool, _ variant: Variant) -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		whiteSpace(.nowrap)
		textAlign(.center)
		border(.none)
		cursor(disabled ? cursorBaseDisabled : (isActive ? .default : cursorBaseHover))
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		position(.relative)
		fontFamily(typographyFontSans)

		switch variant {
		case .quiet:
			height(px(44))
			padding(0, spacing12)
			fontSize(fontSizeSmall14)
			fontWeight(fontWeightNormal)
			lineHeight(lineHeightSmall22)
			backgroundColor(.transparent)
			borderRadius(borderRadiusPill)

			if isActive {
				color(colorBase)
				fontWeight(fontWeightSemiBold)
			} else {
				color(colorSubtle)
			}

		case .solid:
			padding(spacing8, spacing16)
			fontSize(fontSizeSmall14)
			lineHeight(lineHeightXSmall20)
			borderRadius(borderRadiusPill)

			if isActive {
				color(colorInvertedFixed)
				backgroundColor(colorBlue)
				fontWeight(fontWeightBold)
			} else {
				color(colorBlue)
				backgroundColor(.transparent)
				fontWeight(fontWeightNormal)
			}
		}

		if disabled {
			color(colorDisabled)
			cursor(cursorBaseDisabled)
		}

		pseudoClass(.hover, not(.disabled), not(attribute(.ariaSelected, true))) {
			color(colorBase).important()

			if variant == .solid {
				backgroundColor(backgroundColorInteractiveSubtleHover).important()
			}
		}

		pseudoClass(.focusVisible) {
			outline(borderWidthThick, .solid, borderColorBlue).important()
			outlineOffset(px(-2)).important()
		}

		pseudoClass(.focus) {
			outline(.none)
		}
	}

	@CSSBuilder
	private func tabPanelCSS(_ framed: Bool) -> [CSSProtocol] {
		if framed {
			padding(spacing16)
		}
	}

	@CSSBuilder
	private func tabsScrollButtonCSS() -> [CSSProtocol] {
		display(.none)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconMedium)
		height(perc(100))
		padding(spacing8)
		backgroundColor(backgroundColorBase)
		border(.none)
		cursor(cursorBaseHover)
		flexShrink(0)
		color(colorBase)

		pseudoClass(.hover) {
			backgroundColor(backgroundColorInteractiveSubtleHover).important()
		}

		pseudoClass(.active) {
			backgroundColor(backgroundColorInteractiveSubtleActive).important()
		}

		pseudoClass(.disabled) {
			color(colorDisabled).important()
			cursor(cursorBaseDisabled).important()
		}
	}

	public func render(indent: Int = 0) -> String {
		let active = activeTab ?? tabs.first?.name ?? ""

		return div {
			div {
				// Scroll buttons only for quiet variant (solid wraps instead)
				if variant == .quiet {
					button { PreviousIconView() }
						.type(.button)
						.class("tabs-scroll-button tabs-scroll-prev")
						.ariaLabel("Scroll to previous tabs")
						.data("scroll", "prev")
						.style {
							tabsScrollButtonCSS()
						}
				}

				div {
					for tab in tabs {
						let isActive = tab.name == active
						let tabClass = tab.`class`.isEmpty ? "tab-view" : "tab-view \(tab.`class`)"

						if let url = tab.url {
							// URL tabs render as anchor links (navigation)
							a { tab.label.isEmpty ? tab.name : tab.label }
								.href(url)
								.class(tabClass)
								.role("tab")
								.ariaSelected(isActive)
								.id("tab-\(tab.name)")
								.data("tab-name", tab.name)
								.style {
									tabButtonCSS(isActive, tab.disabled, framed, variant)
									textDecoration(.none)
								}
						} else {
							// Panel-switching tabs render as buttons
							button { tab.label.isEmpty ? tab.name : tab.label }
								.type(.button)
								.class(tabClass)
								.role("tab")
								.ariaSelected(isActive)
								.ariaControls("panel-\(tab.name)")
								.id("tab-\(tab.name)")
								.data("tab-name", tab.name)
								.disabled(tab.disabled)
								.tabindex(isActive ? 0 : -1)
								.style {
									tabButtonCSS(isActive, tab.disabled, framed, variant)
								}
						}
					}
				}
				.class("tabs-list")
				.role("tablist")
				.style {
					tabsListCSS(variant)
				}

				if variant == .quiet {
					button { NextIconView() }
						.type(.button)
						.class("tabs-scroll-button tabs-scroll-next")
						.ariaLabel("Scroll to next tabs")
						.data("scroll", "next")
						.style {
							tabsScrollButtonCSS()
						}
				}
			}
			.class("tabs-header")
			.style {
				tabsHeaderCSS(variant)
			}

			for tab in tabs {
				let isActive = tab.name == active
				section {
					tab.content
				}
				.class("tab-panel")
				.role("tabpanel")
				.id("panel-\(tab.name)")
				.ariaLabelledby("tab-\(tab.name)")
				.tabindex(0)
				.hidden(!isActive)
				.style {
					tabPanelCSS(framed)
				}
			}
		}
		.class([
			"tabs-view",
			framed ? "tabs-framed" : nil,
			variant == .solid ? "tabs-solid" : nil,
			`class`.isEmpty ? nil : `class`
		].compactMap { $0 }.joined(separator: " "))
		.data("active-tab", active)
		.style {
			tabsViewCSS(framed)
		}
		.render(indent: indent)
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

private class TabsInstance: @unchecked Sendable {
	private var tabsElement: Element
	private var tabButtons: [Element] = []
	private var tabPanels: [Element] = []
	private var scrollPrevButton: Element?
	private var scrollNextButton: Element?
	private var tabsList: Element?
	private var activeTabName: String = ""

	init(tabs: Element) {
		self.tabsElement = tabs
		self.tabButtons = Array(tabs.querySelectorAll(".tabs-list [role='tab']"))
		self.tabPanels = Array(tabs.querySelectorAll(".tab-panel"))
		self.scrollPrevButton = tabs.querySelector("[\(data("scroll"))='prev']")
		self.scrollNextButton = tabs.querySelector("[\(data("scroll"))='next']")
		self.tabsList = tabs.querySelector(".tabs-list")
		self.activeTabName = tabs.getAttribute(data("active-tab")) ?? ""

		bindEvents()
		updateScrollButtons()
	}

	private func bindEvents() {
		for button in tabButtons {
			_ = button.addEventListener(.click) { [self, button] _ in
				guard let tabName = button.getAttribute(data("tab-name")) else { return }
				self.selectTab(tabName, setFocus: false)
			}

			_ = button.addEventListener(.keydown) { [self, button] (event: CallbackString) in
				event.withCString { eventPtr in
					let key = String(cString: eventPtr)
					self.handleKeydown(key: key, currentButton: button)
				}
			}
		}

		if let prevBtn = scrollPrevButton {
			_ = prevBtn.addEventListener(.click) { [self] _ in
				self.scrollTabs(direction: -1)
			}
		}

		if let nextBtn = scrollNextButton {
			_ = nextBtn.addEventListener(.click) { [self] _ in
				self.scrollTabs(direction: 1)
			}
		}

		if let list = tabsList {
			_ = list.addEventListener(.scroll) { [self] _ in
				self.updateScrollButtons()
			}
		}
	}

	private func selectTab(_ tabName: String, setFocus: Bool) {
		activeTabName = tabName

		for button in tabButtons {
			let isActive = stringEquals(button.getAttribute(data("tab-name")) ?? "", tabName)
			button.setAttribute(.ariaSelected, isActive ? true : false)
			button.setAttribute(.tabindex, isActive ? 0 : -1)

			if isActive {
				_ = button.classList.add("tab-active")
				if setFocus {
					button.focus()
				}
			} else {
				_ = button.classList.remove("tab-active")
			}
		}

		for panel in tabPanels {
			if let panelId = panel.getAttribute(.id) {
				let shouldShow = stringEquals(panelId, "panel-\(tabName)")
				if shouldShow {
					panel.removeAttribute("hidden")
				} else {
					panel.setAttribute("hidden", "")
				}
			}
		}

		tabsElement.setAttribute("data-active-tab", tabName)

		let event = CustomEvent(type: "update:active", detail: tabName)
		tabsElement.dispatchEvent(event)
	}

	private func handleKeydown(key: String, currentButton: Element) {
		guard let currentIndex = tabButtons.firstIndex(where: { stringEquals($0.idString ?? "", currentButton.idString ?? "") }) else { return }

		var targetIndex: Int?

		if stringEquals(key, "ArrowLeft") || stringEquals(key, "Left") {
			targetIndex = currentIndex > 0 ? currentIndex - 1 : tabButtons.count - 1
		} else if stringEquals(key, "ArrowRight") || stringEquals(key, "Right") {
			targetIndex = currentIndex < tabButtons.count - 1 ? currentIndex + 1 : 0
		} else if stringEquals(key, "Home") {
			targetIndex = 0
		} else if stringEquals(key, "End") {
			targetIndex = tabButtons.count - 1
		}

		if let index = targetIndex {
			let targetButton = tabButtons[index]
			guard let tabName = targetButton.getAttribute("data-tab-name") else { return }
			selectTab(tabName, setFocus: true)
		}
	}

	private func scrollTabs(direction: Int) {
		guard let list = tabsList else { return }
		let scrollAmount = 200.0 * Double(direction)
		list.scrollBy(x: scrollAmount, y: 0)
	}

	private func updateScrollButtons() {
		guard let list = tabsList,
		      let prev = scrollPrevButton,
		      let next = scrollNextButton else { return }

		let hasOverflow = list.scrollWidth > list.clientWidth
		let canScrollLeft = list.scrollLeft > 0
		let canScrollRight = list.scrollLeft < (list.scrollWidth - list.clientWidth - 1)

		if hasOverflow {
			prev.style.setProperty("display", "flex")
			next.style.setProperty("display", "flex")

			if canScrollLeft {
				prev.removeAttribute("disabled")
			} else {
				prev.setAttribute("disabled", "")
			}

			if canScrollRight {
				next.removeAttribute("disabled")
			} else {
				next.setAttribute("disabled", "")
			}
		} else {
			prev.style.setProperty("display", "none")
			next.style.setProperty("display", "none")
		}
	}
}

public class TabsHydration: @unchecked Sendable {
	private var instances: [TabsInstance] = []

	public init() {
		hydrateAllTabs()
	}

	private func hydrateAllTabs() {
		let allTabs = document.querySelectorAll(".tabs-view")

		for tabs in allTabs {
			let instance = TabsInstance(tabs: tabs)
			instances.append(instance)
		}
	}
}

#endif
