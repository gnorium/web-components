#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ColorSchemeToggleView: HTML {
	let `class`: String
	let size: Length

	public init(
		class: String = "",
		size: Length = sizeIconMedium
	) {
		self.class = `class`
		self.size = size
	}

	public func render(indent: Int = 0) -> String {
		button {
			span {
				IconView(icon: { size in
					LightModeIconView(width: size, height: size)
				}, size: .medium)
			}
			.class("color-scheme-toggle-icon-light")
			.style {
				display(.inlineBlock)
				lineHeight(1)
				transition(transitionPropertyFade, transitionDurationMedium, transitionTimingFunctionUser)
			}
			span {
				IconView(icon: { size in
					DarkModeIconView(width: size, height: size)
				}, size: .medium)
			}
			.class("color-scheme-toggle-icon-dark")
			.style {
				display(.none)
				lineHeight(1)
				transition(transitionPropertyFade, transitionDurationMedium, transitionTimingFunctionUser)
			}
		}
		.class(`class`.isEmpty ? "color-scheme-toggle-view" : "color-scheme-toggle-view \(`class`)")
		.ariaLabel("Toggle color scheme")
		.style {
			background(.transparent)
			border(.none)
			cursor(.pointer)
			padding(0)
			display(.flex)
			alignItems(.center)
			justifyContent(.center)
			fontFamily(typographyFontSerif)
			color(colorBase)
			transition(.all, s(0.2), .easeInOut)
			borderRadius(borderRadiusBase)

			pseudoClass(.focus) {
				outline(borderWidthBase, .solid, borderColorProgressiveFocus).important()
				boxShadow(boxShadowOutsetSmall, boxShadowColorProgressiveFocus).important()
			}
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

public class ColorSchemeToggleHydration: @unchecked Sendable {
	nonisolated(unsafe) private var button: Element?
	nonisolated(unsafe) private var lightIcon: Element?
	nonisolated(unsafe) private var darkIcon: Element?
	nonisolated(unsafe) private var currentScheme: CSSPrefersColorScheme = .light

	public init?() {
		button = document.querySelector(".color-scheme-toggle-view")
		lightIcon = document.querySelector(".color-scheme-toggle-icon-light")
		darkIcon = document.querySelector(".color-scheme-toggle-icon-dark")

		guard button != nil, lightIcon != nil, darkIcon != nil else {
			return nil
		}

		initializeFromSystemPreference()

		setupMediaQueryListener()

		bindEvents()
	}

	private func setupMediaQueryListener() {
		// Listen for system preference changes (sunrise/sunset)
		window.onMediaQueryChange(prefersColorScheme(.dark)) { [self] prefersDark in
			// Apply system preference and update state
			self.currentScheme = prefersDark ? .dark : .light
			self.applyColorScheme()
		}
	}

	nonisolated private func initializeFromSystemPreference() {
		// Check localStorage first, fall back to system preference
		if let saved = localStorage.getItem("color-scheme") {
			// Manual string comparison to avoid stdlib dependency
			let isDark = saved.withCString { ptr in
				ptr[0] == 100 && ptr[1] == 97 && ptr[2] == 114 && ptr[3] == 107 && ptr[4] == 0 // "dark"
			}
			currentScheme = isDark ? .dark : .light
		} else {
			let prefersDark = window.matchMedia(prefersColorScheme(.dark))
			currentScheme = prefersDark ? .dark : .light
		}
		applyColorScheme()
	}

	nonisolated private func bindEvents() {
		guard let btn = button else {
			return
		}
		_ = btn.addEventListener(.click) { [self] _ in
			self.toggle()
		}
	}

	nonisolated private func toggle() {
		// Simple state toggle - no DOM parsing needed
		switch currentScheme {
			case .light:
				currentScheme = .dark
			case .dark:
				currentScheme = .light
		}
		applyColorScheme()
	}

	nonisolated private func applyColorScheme() {
		let htmlElement = document.querySelector("html")

		switch currentScheme {
			case .dark:
				htmlElement?.dataset.colorScheme = "dark"
				lightIcon?.style.display(.none)
				darkIcon?.style.display(.inlineBlock)
				localStorage.setItem("color-scheme", "dark")
			case .light:
				htmlElement?.dataset.colorScheme = "light"
				lightIcon?.style.display(.inlineBlock)
				darkIcon?.style.display(.none)
				localStorage.setItem("color-scheme", "light")
		}
	}
}

#endif
