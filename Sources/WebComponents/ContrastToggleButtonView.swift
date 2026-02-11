#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ContrastToggleButtonView: HTMLProtocol {
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
						LessContrastIconView(width: s, height: s)
					}, size: iconSize)
				}
				.class("contrast-toggle-button-icon-less")
				.style {
					display(.flex)
					transition(transitionPropertyFade, transitionDurationMedium, transitionTimingFunctionUser)
				}
				span {
					IconView(icon: { s in
						MoreContrastIconView(width: s, height: s)
					}, size: iconSize)
				}
				.class("contrast-toggle-button-icon-more")
				.style {
					display(.none)
					transition(transitionPropertyFade, transitionDurationMedium, transitionTimingFunctionUser)
				}
			},
			modelValue: false,
			weight: .plain,
			iconOnly: true,
			ariaLabel: "Toggle contrast",
			indicateSelection: false,
			size: size,
			class: `class`.isEmpty ? "contrast-toggle-button-view" : "contrast-toggle-button-view \(`class`)"
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

public class ContrastToggleButtonHydration: @unchecked Sendable {
	nonisolated(unsafe) private var buttons: [Element] = []
	nonisolated(unsafe) private var currentContrast: CSSPrefersContrast = .less

	public init?() {
		let allButtons = document.querySelectorAll(".contrast-toggle-button-view")
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
		// Listen for system preference changes
		window.onMediaQueryChange(prefersContrast(.more)) { [self] prefersMore in
			// Apply system preference and update state
			self.currentContrast = prefersMore ? .more : .less
			self.applyContrast()
		}
	}

	nonisolated private func initializeFromSystemPreference() {
		// Check localStorage first, fall back to system preference
		if let saved = localStorage.getItem("contrast") {
			let isMore = saved.withCString { ptr in
				ptr[0] == 109 && ptr[1] == 111 && ptr[2] == 114 && ptr[3] == 101 && ptr[4] == 0 // "more"
			}
			currentContrast = isMore ? .more : .less
		} else {
			let prefersMore = window.matchMedia(prefersContrast(.more))
			currentContrast = prefersMore ? .more : .less
		}
		applyContrast()
	}

	nonisolated private func bindEvents() {
		// Listen for toggle-button-update from all buttons
		for button in buttons {
			_ = button.addEventListener("toggle-button-update") { [self] (event: CallbackString) in
				let isMore = event.detail.withCString { ptr in
					ptr[0] == 116 && ptr[1] == 114 && ptr[2] == 117 && ptr[3] == 101 && ptr[4] == 0 // "true"
				}
				self.currentContrast = isMore ? .more : .less
				self.applyContrast()
			}
		}
	}

	nonisolated private func applyContrast() {
		let htmlElement = document.querySelector("html")

		switch currentContrast {
		case .more:
			htmlElement?.dataset.contrast("more")
			localStorage.setItem("contrast", "more")
		case .less:
			htmlElement?.dataset.contrast("less")
			localStorage.setItem("contrast", "less")
		default:
			break
		}

		// Update all buttons
		for button in buttons {
			let lessIcon = button.querySelector(".contrast-toggle-button-icon-less")
			let moreIcon = button.querySelector(".contrast-toggle-button-icon-more")

			switch currentContrast {
			case .more:
				button.setAttribute("aria-pressed", "true")
				lessIcon?.style.display(.none)
				moreIcon?.style.display(.flex)
			case .less:
				button.setAttribute("aria-pressed", "false")
				lessIcon?.style.display(.flex)
				moreIcon?.style.display(.none)
			default:
				break
			}
		}
	}
}

#endif
