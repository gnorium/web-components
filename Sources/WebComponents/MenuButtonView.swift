#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// MenuButton component following Wikimedia Codex design system specification
/// A ToggleButton that displays a Menu with actions when toggled on.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/menu-button.html
public struct MenuButtonView: HTML {
	public struct MenuItem: Sendable {
		public let value: String
		public let label: String
		public let icon: (any HTML)?
		public let url: String?
		public let disabled: Bool
		public let destructive: Bool

		public init(
			value: String,
			label: String,
			url: String? = nil,
			icon: (any HTML)? = nil,
			disabled: Bool = false,
			destructive: Bool = false
		) {
			self.value = value
			self.label = label
			self.url = url
			self.icon = icon
			self.disabled = disabled
			self.destructive = destructive
		}
	}

	let buttonLabel: String
	let buttonIcon: (any HTML)?
	let iconOnly: Bool
	let menuItems: [MenuItem]
	let buttonWeight: ButtonView.ButtonWeight
	let disabled: Bool
	let ariaLabel: String?
	let size: ButtonView.ButtonSize
	let `class`: String
	let buttonFontWeight: CSSFontWeight
    let indicateSelection: Bool
	
	public init(
		buttonLabel: String,
		buttonIcon: (any HTML)? = nil,
		iconOnly: Bool = false,
		menuItems: [MenuItem],
		buttonWeight: ButtonView.ButtonWeight = .normal,
		disabled: Bool = false,
		ariaLabel: String? = nil,
		size: ButtonView.ButtonSize = .medium,
		class: String = "",
		buttonFontWeight: CSSFontWeight = fontWeightBold,
		indicateSelection: Bool = false
	) {
		self.buttonLabel = buttonLabel
		self.buttonIcon = buttonIcon
		self.iconOnly = iconOnly
		self.menuItems = menuItems
		self.buttonWeight = buttonWeight
		self.disabled = disabled
		self.ariaLabel = ariaLabel
		self.size = size
		self.`class` = `class`
		self.buttonFontWeight = buttonFontWeight
		self.indicateSelection = indicateSelection
	}

	public func render(indent: Int = 0) -> String {
		div {
			// Toggle Button
			ToggleButtonView(
				label: buttonLabel,
				icon: buttonIcon,
				modelValue: false,
				weight: buttonWeight,
				disabled: disabled,
				iconOnly: iconOnly,
				ariaLabel: ariaLabel,
				ariaExpanded: false,
				indicateSelection: indicateSelection,
				size: size,
				class: "menu-button-trigger",
				buttonFontWeight: buttonFontWeight
			)

			// Menu
			div {
				menuItems.map { item in
					let itemContent: [HTML] = [
						item.icon.map { icon in span { icon }.class("menu-item-icon").ariaHidden(true).style { menuItemIconCSS() } },
						span { item.label }.class("menu-item-text").style { menuItemTextCSS() }
					].compactMap { $0 }

					if let url = item.url {
						return a {
							itemContent
						}
						.href(url)
						.class(item.destructive ? "menu-item menu-item-destructive" : "menu-item")
						.data("value", item.value)
						.data("menu-item", true)
						.role(.menuitem)
						.tabindex(item.disabled ? -1 : 0)
						.ariaDisabled(item.disabled)
						.style {
							menuItemCSS(item)
							textDecoration(.none)
						}
					} else {
						return div {
							itemContent
						}
						.class(item.destructive ? "menu-item menu-item-destructive" : "menu-item")
						.data("value", item.value)
						.data("menu-item", true)
						.role(.menuitem)
						.tabindex(item.disabled ? -1 : 0)
						.ariaDisabled(item.disabled)
						.style {
							menuItemCSS(item)
						}
					}
				}
			}
			.class("menu-button-menu")
			.data("menu-button-menu", true)
			.role(.menu)
			.style {
				menuButtonMenuCSS()
			}
		}
		.class(`class`.isEmpty ? "menu-button-view" : "menu-button-view \(`class`)")
		.data("menu-button", true)
		.style {
			menuButtonViewCSS()
		}
		.render(indent: indent)
	}

    @CSSBuilder
	private func menuButtonViewCSS() -> [CSS] {
		position(.relative)
		display(.inlineBlock)
	}

	@CSSBuilder
	private func menuButtonMenuCSS() -> [CSS] {
		position(.absolute)
		top(perc(100))
		left(0)
		marginTop(spacing4)
		minWidth(px(160))
		maxWidth(px(320))
		backgroundColor(backgroundColorBase)
		border(borderWidthBase, .solid, borderColorBase)
		borderRadius(borderRadiusBase)
		boxShadow(boxShadowMedium)
		zIndex(1000)
		display(.none)
		maxHeight(px(400))
		overflowY(.auto)
		boxSizing(.borderBox)
	}

	@CSSBuilder
	private func menuItemCSS(_ item: MenuItem) -> [CSS] {
		display(.flex)
		alignItems(.center)
		gap(spacing12)
		padding(spacing8, spacing12)
		fontSize(fontSizeSmall14)
		lineHeight(1.5)
		cursor(.pointer)
		userSelect(.none)
		boxSizing(.borderBox)

		if item.destructive {
			color(colorDestructive)
		} else {
			color(colorBase)
		}

		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

		pseudoClass(.hover, not(.disabled)) {
			if item.destructive {
				backgroundColor(backgroundColorDestructiveSubtle).important()
				color(colorDestructive).important()
			} else {
				backgroundColor(backgroundColorInteractiveSubtle).important()
				color(colorProgressive).important()
			}
		}

		pseudoClass(.focus) {
			if item.destructive {
				backgroundColor(backgroundColorDestructiveSubtle).important()
				outline(borderWidthThick, .solid, colorDestructive).important()
			} else {
				backgroundColor(backgroundColorInteractiveSubtle).important()
				outline(borderWidthThick, .solid, colorProgressive).important()
			}
		}

		if item.disabled {
			color(colorDisabled).important()
			cursor(.default).important()
			pointerEvents(.none).important()
		}
	}

	@CSSBuilder
	private func menuItemIconCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconSmall)
		height(sizeIconSmall)
		flexShrink(0)
	}

	@CSSBuilder
	private func menuItemTextCSS() -> [CSS] {
		flex(1)
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

public class MenuButtonHydration: @unchecked Sendable {
	private var instances: [MenuButtonInstance] = []

	public init() {
		hydrateAllMenuButtons()
	}

	private func hydrateAllMenuButtons() {
		let allMenuButtons = document.querySelectorAll("[data-menu-button=\"true\"]")

		for menuButton in allMenuButtons {
			let instance = MenuButtonInstance(menuButton: menuButton)
			instances.append(instance)
		}
	}
}

private class MenuButtonInstance: @unchecked Sendable {
	private var menuButton: Element
	private var trigger: Element?
	private var menu: Element?
	private var menuItems: [Element] = []
	private var isOpen: Bool = false
	private var currentFocusIndex: Int = -1

	init(menuButton: Element) {
		self.menuButton = menuButton

		trigger = menuButton.querySelector(".menu-button-trigger")
		menu = menuButton.querySelector("[data-menu-button-menu=\"true\"]")

		if let menu = menu {
			menuItems = Array(menu.querySelectorAll("[data-menu-item=\"true\"]"))
		}

		bindEvents()
	}

	private func bindEvents() {
		guard let trigger else { return }

		// Toggle button click
		_ = trigger.addEventListener(.click) { [self] _ in
			self.toggleMenu()
		}

		// Menu item clicks
		for (index, item) in menuItems.enumerated() {
			_ = item.addEventListener(.click) { [self] _ in
				self.selectMenuItem(item)
			}

			_ = item.addEventListener(.keydown) { [self] (event: CallbackString) in
				self.handleMenuItemKeydown(event, index: index)
			}

			_ = item.addEventListener(.focus) { [self] _ in
				self.currentFocusIndex = index
			}
		}

		// Click outside to close
		_ = document.addEventListener(.click) { [self] (event: CallbackString) in
			self.handleClickOutside(event)
		}

		// Keyboard navigation on trigger
		_ = trigger.addEventListener(.keydown) { [self] (event: CallbackString) in
			self.handleTriggerKeydown(event)
		}
	}

	private func toggleMenu() {
		if isOpen {
			closeMenu()
		} else {
			openMenu()
		}
	}

	private func openMenu() {
		menu?.style.display(.block)
		trigger?.setAttribute("aria-expanded", "true")
		isOpen = true

		// Focus first menu item
		if !menuItems.isEmpty {
			menuItems[0].focus()
			currentFocusIndex = 0
		}
	}

	private func closeMenu() {
		menu?.style.display(.none)
		trigger?.setAttribute("aria-expanded", "false")
		isOpen = false
		currentFocusIndex = -1
		trigger?.focus()
	}

	private func selectMenuItem(_ item: Element) {
		guard let ariaDisabled = item.getAttribute("aria-disabled"),
			  !stringEquals(ariaDisabled, "true") else { return }

		guard let value = item.getAttribute("data-value") else { return }

		// Emit custom event
		let event = CustomEvent(type: "menu-button-select", detail: value)
		menuButton.dispatchEvent(event)

		closeMenu()
	}

	private func handleTriggerKeydown(_ event: CallbackString) {
		event.withCString { eventPtr in
			let key = String(cString: eventPtr)

			if stringEquals(key, "ArrowDown") {
				if !isOpen {
					openMenu()
				}
			} else if stringEquals(key, "ArrowUp") {
				if !isOpen {
					openMenu()
				}
			} else if stringEquals(key, "Escape") {
				if isOpen {
					closeMenu()
				}
			}
		}
	}

	private func handleMenuItemKeydown(_ event: CallbackString, index: Int) {
		event.withCString { eventPtr in
			let key = String(cString: eventPtr)

			if stringEquals(key, "ArrowDown") {
				focusNextItem()
			} else if stringEquals(key, "ArrowUp") {
				focusPreviousItem()
			} else if stringEquals(key, "Home") {
				focusFirstItem()
			} else if stringEquals(key, "End") {
				focusLastItem()
			} else if stringEquals(key, "Escape") {
				closeMenu()
			} else if stringEquals(key, "Enter") || stringEquals(key, " ") {
				selectMenuItem(menuItems[index])
			}
		}
	}

	private func focusNextItem() {
		guard !menuItems.isEmpty else { return }
		currentFocusIndex = (currentFocusIndex + 1) % menuItems.count
		menuItems[currentFocusIndex].focus()
	}

	private func focusPreviousItem() {
		guard !menuItems.isEmpty else { return }
		currentFocusIndex = currentFocusIndex - 1
		if currentFocusIndex < 0 {
			currentFocusIndex = menuItems.count - 1
		}
		menuItems[currentFocusIndex].focus()
	}

	private func focusFirstItem() {
		guard !menuItems.isEmpty else { return }
		currentFocusIndex = 0
		menuItems[currentFocusIndex].focus()
	}

	private func focusLastItem() {
		guard !menuItems.isEmpty else { return }
		currentFocusIndex = menuItems.count - 1
		menuItems[currentFocusIndex].focus()
	}

	private func handleClickOutside(_ event: CallbackString) {
		guard isOpen, let target = event.target else { return }

		if !menuButton.contains(target) {
			closeMenu()
		}
	}
}

#endif
