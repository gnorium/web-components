#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A button group for selecting color scheme (Light / Dark).
/// Renders two option buttons with icons. Hydrated by ColorSchemeButtonGroupHydration.
public struct ColorSchemeButtonGroupView: HTMLProtocol {
	let `class`: String

	public init(class: String = "") {
		self.class = `class`
	}

	public func render(indent: Int = 0) -> String {
		div {
			optionButton(value: "light", label: "Light") {
				IconView(icon: { s in LightModeIconView(width: s, height: s) }, size: .medium)
			}
			optionButton(value: "dark", label: "Dark") {
				IconView(icon: { s in DarkModeIconView(width: s, height: s) }, size: .medium)
			}
		}
		.class(`class`.isEmpty ? "button-group-view color-scheme-button-group-view" : "button-group-view color-scheme-button-group-view \(`class`)")
		.role(.group)
		.ariaLabel("Color scheme")
		.style {
			display(.flex)
			flexDirection(.column)
			gap(spacing4)
		}
		.render(indent: indent)
	}

	private func optionButton(value: String, label: String, @HTMLBuilder icon: () -> HTMLProtocol) -> HTMLProtocol {
		div {
			span { icon() }
			.class("option-icon")
			.ariaHidden(true)
			.style {
				display(.flex)
				alignItems(.center)
				justifyContent(.center)
				width(sizeIconMedium)
				height(sizeIconMedium)
			}
			span { label }
		}
		.class("button-group-button")
		.data("value", value)
		.tabindex(0)
		.role(.button)
		.ariaDisabled(false)
		.style {
			display(.flex)
			alignItems(.center)
			gap(spacing8)
			padding(spacing8, spacing12)
			fontFamily(fontFamilyBase)
			fontSize(fontSizeMedium16)
			fontWeight(fontWeightNormal)
			color(colorBase)
			backgroundColor(backgroundColorBase)
			borderWidth(borderWidthBase)
			borderStyle(.solid)
			borderColor(borderColorBase)
			borderRadius(borderRadiusPill)
			cursor(.pointer)
			transition(.all, s(0.1), .ease)
			userSelect(.none)

			pseudoClass(.hover) {
				backgroundColor(backgroundColorInteractive)
			}
		}
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

/// Hydrates all ColorSchemeButtonGroupView instances on the page.
/// Initializes from localStorage / system preference, binds click events,
/// and applies color scheme changes to the document.
public class ColorSchemeButtonGroupHydration: @unchecked Sendable {
	nonisolated(unsafe) private var groups: [Element] = []

	public init?() {
		let allGroups = document.querySelectorAll(".color-scheme-button-group-view")
		for group in allGroups {
			groups.append(group)
		}
		guard !groups.isEmpty else { return nil }

		initialize()
		bindEvents()
	}

	private nonisolated func initialize() {
		var scheme: CSSPrefersColorScheme = .light
		if let saved = localStorage.getItem("color-scheme") {
			let isDark = saved.withCString { ptr in
				ptr[0] == 100 && ptr[1] == 97 && ptr[2] == 114 && ptr[3] == 107 && ptr[4] == 0 // "dark"
			}
			scheme = isDark ? .dark : .light
		} else {
			let prefersDark = window.matchMedia(prefersColorScheme(.dark))
			scheme = prefersDark ? .dark : .light
		}
		applyScheme(scheme)
	}

	private nonisolated func bindEvents() {
		for group in groups {
			let buttons = group.querySelectorAll(".button-group-button")
			for button in buttons {
				_ = button.addEventListener("button-group-click") { [self] (event: CallbackString) in
					let isDark = event.detail.withCString { ptr in
						ptr[0] == 100 && ptr[1] == 97 && ptr[2] == 114 && ptr[3] == 107 // "dark"
					}
					self.applyScheme(isDark ? .dark : .light)
				}
			}
		}
	}

	private nonisolated func applyScheme(_ scheme: CSSPrefersColorScheme) {
		let htmlElement = document.querySelector("html")
		switch scheme {
		case .dark:
			htmlElement?.dataset.colorScheme("dark")
			localStorage.setItem("color-scheme", "dark")
		case .light:
			htmlElement?.dataset.colorScheme("light")
			localStorage.setItem("color-scheme", "light")
		}

		let selectedValue: String
		switch scheme {
		case .dark: selectedValue = "dark"
		case .light: selectedValue = "light"
		}

		for group in groups {
			updateSelection(group, selectedValue: selectedValue)
		}
	}

	private nonisolated func updateSelection(_ group: Element, selectedValue: String) {
		let buttons = group.querySelectorAll(".button-group-button")
		for button in buttons {
			if let value = button.getAttribute("data-value") {
				if stringEquals(value, selectedValue) {
					button.style.backgroundColor(backgroundColorBlue)
					button.style.color(colorInvertedFixed)
					button.style.borderColor(borderColorBlue)
				} else {
					button.style.backgroundColor(backgroundColorBase)
					button.style.color(colorBase)
					button.style.borderColor(borderColorBase)
				}
			}
		}
	}
}

#endif
