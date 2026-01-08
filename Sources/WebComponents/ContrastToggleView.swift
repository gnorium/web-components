#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ContrastToggleView: HTML {
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
					LessContrastIconView(width: size, height: size)
				}, size: .medium)
			}
			.class("contrast-toggle-icon-less")
			.style {
				display(.inlineBlock)
				lineHeight(1)
				transition(transitionPropertyFade, transitionDurationMedium, transitionTimingFunctionUser)
			}
			span {
				IconView(icon: { size in
					MoreContrastIconView(width: size, height: size)
				}, size: .medium)
			}
			.class("contrast-toggle-icon-more")
			.style {
				display(.none)
				lineHeight(1)
				transition(transitionPropertyFade, transitionDurationMedium, transitionTimingFunctionUser)
			}
		}
		.class(`class`.isEmpty ? "contrast-toggle-view" : "contrast-toggle-view \(`class`)")
		.ariaLabel("Toggle contrast")
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

public class ContrastToggleHydration: @unchecked Sendable {
	nonisolated(unsafe) private var button: Element?
	nonisolated(unsafe) private var lessIcon: Element?
	nonisolated(unsafe) private var moreIcon: Element?
	nonisolated(unsafe) private var currentContrast: CSSPrefersContrast = .less

	public init?() {
		button = document.querySelector(".contrast-toggle-view")
		lessIcon = document.querySelector(".contrast-toggle-icon-less")
		moreIcon = document.querySelector(".contrast-toggle-icon-more")

		guard button != nil, lessIcon != nil, moreIcon != nil else {
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
			// Manual string comparison to avoid stdlib dependency
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
		guard let btn = button else {
			return
		}
		_ = btn.on(.click) { [self] _ in
			self.toggle()
		}
	}

	nonisolated private func toggle() {
		// Simple state toggle
		switch currentContrast {
		case .less:
			currentContrast = .more
		case .more:
			currentContrast = .less
		default:
			break
		}
		applyContrast()
	}

	nonisolated private func applyContrast() {
		let htmlElement = document.querySelector("html")

		switch currentContrast {
		case .more:
			htmlElement?.dataset.contrast = "more"
			lessIcon?.style.display(.none)
			moreIcon?.style.display(.inlineBlock)
			localStorage.setItem("contrast", "more")
		case .less:
			htmlElement?.dataset.contrast = "less"
			lessIcon?.style.display(.inlineBlock)
			moreIcon?.style.display(.none)
			localStorage.setItem("contrast", "less")
		default:
			break
		}
	}
}

#endif
