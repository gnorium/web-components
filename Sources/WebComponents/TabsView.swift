#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Tabs component following Wikimedia Codex design system specification
/// Tabs consist of two or more tab items for navigating between different sections of content.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/tabs.html
public struct TabsView: HTML {
	let tabs: [TabView]
	let activeTab: String?
	let framed: Bool
	let `class`: String

	public init(
		tabs: [TabView],
		activeTab: String? = nil,
		framed: Bool = false,
		class: String = ""
	) {
		self.tabs = tabs
		self.activeTab = activeTab ?? tabs.first?.name
		self.framed = framed
		self.`class` = `class`
	}

	@CSSBuilder
	private func tabsViewCSS(_ framed: Bool) -> [CSS] {
		display(.block)
		fontFamily(typographyFontSans)

		if framed {
			border(borderWidthBase, .solid, borderColorSubtle)
			borderRadius(borderRadiusBase)
		}
	}

	@CSSBuilder
	private func tabsHeaderCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		position(.relative)
		overflow(.hidden)
		borderBottom(borderWidthBase, .solid, borderColorSubtle)
	}

	@CSSBuilder
	private func tabsListCSS() -> [CSS] {
		display(.flex)
		gap(0)
		margin(0)
		padding(0)
		listStyle(.none)
		overflow(.auto)
		scrollbarWidth(.none)
		flexGrow(1)

		pseudoElement(.webkitScrollbar) {
			display(.none).important()
		}
	}

	@CSSBuilder
	private func tabButtonCSS(_ isActive: Bool, _ disabled: Bool, _ framed: Bool) -> [CSS] {
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
			color(colorProgressive)
			fontWeight(fontWeightBold)

			if !framed {
				borderBottom(borderWidthThick, .solid, borderColorProgressive)
			} else {
				backgroundColor(backgroundColorBase)
			}
		} else {
			color(colorBase)
			borderBottom(borderWidthThick, .solid, .transparent)
		}

		if disabled {
			color(colorDisabled)
			cursor(cursorBaseDisabled)
		}

		if !disabled && !isActive {
			pseudoClass(.hover) {
				color(colorProgressive).important()
				backgroundColor(backgroundColorProgressiveSubtle).important()
			}

			pseudoClass(.active) {
				backgroundColor(backgroundColorProgressiveSubtle).important()
			}
		}

		pseudoClass(.focus) {
			outline(borderWidthThick, .solid, borderColorProgressive).important()
			outlineOffset(px(-2)).important()
		}
	}

	@CSSBuilder
	private func tabPanelCSS(_ framed: Bool) -> [CSS] {
		if framed {
			padding(spacing16)
		} else {
			padding(spacing16, 0)
		}
	}

	@CSSBuilder
	private func tabsScrollButtonCSS() -> [CSS] {
		display(.flex)
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
				button { "◀" }
					.type(.button)
					.class("tabs-scroll-button tabs-scroll-prev")
					.ariaLabel("Scroll to previous tabs")
					.data("scroll", "prev")
					.style {
						tabsScrollButtonCSS()
					}

				div {
					for tab in tabs {
						let isActive = tab.name == active
						button { tab.label.isEmpty ? tab.name : tab.label }
							.type(.button)
							.class(tab.`class`.isEmpty ? "tab-view" : "tab-view \(tab.`class`)")
							.role("tab")
							.ariaSelected(isActive)
							.ariaControls("panel-\(tab.name)")
							.id("tab-\(tab.name)")
							.data("tab-name", tab.name)
							.disabled(tab.disabled)
							.tabindex(isActive ? 0 : -1)
							.style {
								tabButtonCSS(isActive, tab.disabled, framed)
							}
					}
				}
				.class("tabs-list")
				.role("tablist")
				.style {
					tabsListCSS()
				}

				button { "▶" }
					.type(.button)
					.class("tabs-scroll-button tabs-scroll-next")
					.ariaLabel("Scroll to next tabs")
					.data("scroll", "next")
					.style {
						tabsScrollButtonCSS()
					}
			}
			.class("tabs-header")
			.style {
				tabsHeaderCSS()
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
		.class(`class`.isEmpty ? (framed ? "tabs-view tabs-framed" : "tabs-view") : (framed ? "tabs-view tabs-framed \(`class`)" : "tabs-view \(`class`)"))
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
		self.tabPanels = Array(tabs.querySelectorAll(".tabs-panel"))
		self.scrollPrevButton = tabs.querySelector("[\(data("scroll"))='prev']")
		self.scrollNextButton = tabs.querySelector("[\(data("scroll"))='next']")
		self.tabsList = tabs.querySelector(".tabs-list")
		self.activeTabName = tabs.getAttribute(data("active-tab")) ?? ""

		bindEvents()
		updateScrollButtons()
	}

	private func bindEvents() {
		for button in tabButtons {
			_ = button.on(.click) { [self] _ in
				guard let tabName = button.getAttribute(data("tab-name")) else { return }
				self.selectTab(tabName, setFocus: false)
			}

			_ = button.on(.keydown) { [self] (event: CallbackString) in
				event.withCString { eventPtr in
					let key = String(cString: eventPtr)
					self.handleKeydown(key: key, currentButton: button)
				}
			}
		}

		if let prevBtn = scrollPrevButton {
			_ = prevBtn.on(.click) { [self] _ in
				self.scrollTabs(direction: -1)
			}
		}

		if let nextBtn = scrollNextButton {
			_ = nextBtn.on(.click) { [self] _ in
				self.scrollTabs(direction: 1)
			}
		}

		if let list = tabsList {
			_ = list.on(.scroll) { [self] _ in
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

		let canScrollLeft = list.scrollLeft > 0
		let canScrollRight = list.scrollLeft < (list.scrollWidth - list.clientWidth - 1)

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
