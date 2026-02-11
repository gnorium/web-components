#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ColorSchemeToggleButtonView: HTMLProtocol {
	let `class`: String
	let size: ButtonView.ButtonSize

	public init(
		class: String = "",
		size: ButtonView.ButtonSize = .medium
	) {
		self.class = `class`
		self.size = size
	}

	public func render(indent: Int = 0) -> String {
		let iconSize: IconView.IconSize = size == .large ? .medium : size == .small ? .small : .medium
		
		return ToggleButtonView(
			label: "",
			icon: span {
				span {
					IconView(icon: { s in
						LightModeIconView(width: s, height: s)
					}, size: iconSize)
				}
				.class("color-scheme-toggle-button-icon-light")
				.style {
					display(.flex)
					transition(transitionPropertyFade, transitionDurationMedium, transitionTimingFunctionUser)
				}
				span {
					IconView(icon: { s in
						DarkModeIconView(width: s, height: s)
					}, size: iconSize)
				}
				.class("color-scheme-toggle-button-icon-dark")
				.style {
					display(.none)
					transition(transitionPropertyFade, transitionDurationMedium, transitionTimingFunctionUser)
				}
			},
			modelValue: false,
			weight: .plain,
			iconOnly: true,
			ariaLabel: "Toggle color scheme",
			indicateSelection: false,
			size: size,
			class: `class`.isEmpty ? "color-scheme-toggle-button-view" : "color-scheme-toggle-button-view \(`class`)"
		)
		.render(indent: indent)
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

public class ColorSchemeToggleButtonHydration: @unchecked Sendable {
	nonisolated(unsafe) private var buttons: [Element] = []
	nonisolated(unsafe) private var currentScheme: CSSPrefersColorScheme = .light

	public init?() {
		let allButtons = document.querySelectorAll(".color-scheme-toggle-button-view")
		for button in allButtons {
			buttons.append(button)
		}

		guard !buttons.isEmpty else {
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
		// Listen for toggle-button-update from all buttons
		for button in buttons {
			_ = button.addEventListener("toggle-button-update") { [self] (event: CallbackString) in
				let isDark = event.detail.withCString { ptr in
					ptr[0] == 116 && ptr[1] == 114 && ptr[2] == 117 && ptr[3] == 101 && ptr[4] == 0 // "true"
				}
				self.currentScheme = isDark ? .dark : .light
				self.applyColorScheme()
			}
		}
	}

	nonisolated private func applyColorScheme() {
		let htmlElement = document.querySelector("html")

		switch currentScheme {
			case .dark:
				htmlElement?.dataset.colorScheme("dark")
				localStorage.setItem("color-scheme", "dark")
			case .light:
				htmlElement?.dataset.colorScheme("light")
				localStorage.setItem("color-scheme", "light")
		}

		// Update all buttons
		for button in buttons {
			let lightIcon = button.querySelector(".color-scheme-toggle-button-icon-light")
			let darkIcon = button.querySelector(".color-scheme-toggle-button-icon-dark")

			switch currentScheme {
				case .dark:
					button.setAttribute("aria-pressed", "true")
					lightIcon?.style.display(.none)
					darkIcon?.style.display(.flex)
				case .light:
					button.setAttribute("aria-pressed", "false")
					lightIcon?.style.display(.flex)
					darkIcon?.style.display(.none)
			}
		}
	}
}

#endif
