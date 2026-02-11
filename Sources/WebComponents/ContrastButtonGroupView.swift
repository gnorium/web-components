#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A button group for selecting contrast level (Standard / Increased).
/// Renders two option buttons with icons. Hydrated by ContrastButtonGroupHydration.
public struct ContrastButtonGroupView: HTMLProtocol {
	let `class`: String

	public init(class: String = "") {
		self.class = `class`
	}

	public func render(indent: Int = 0) -> String {
		div {
			optionButton(value: "standard", label: "Standard") {
				IconView(icon: { s in LessContrastIconView(width: s, height: s) }, size: .medium)
			}
			optionButton(value: "increased", label: "Increased") {
				IconView(icon: { s in MoreContrastIconView(width: s, height: s) }, size: .medium)
			}
		}
		.class(`class`.isEmpty ? "button-group-view contrast-button-group-view" : "button-group-view contrast-button-group-view \(`class`)")
		.role(.group)
		.ariaLabel("Contrast")
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

/// Hydrates all ContrastButtonGroupView instances on the page.
/// Initializes from localStorage / system preference, binds click events,
/// and applies contrast changes to the document.
public class ContrastButtonGroupHydration: @unchecked Sendable {
	nonisolated(unsafe) private var groups: [Element] = []

	public init?() {
		let allGroups = document.querySelectorAll(".contrast-button-group-view")
		for group in allGroups {
			groups.append(group)
		}
		guard !groups.isEmpty else { return nil }

		initialize()
		bindEvents()
	}

	private nonisolated func initialize() {
		var contrast: CSSPrefersContrast = .less
		if let saved = localStorage.getItem("contrast") {
			let isMore = saved.withCString { ptr in
				ptr[0] == 109 && ptr[1] == 111 && ptr[2] == 114 && ptr[3] == 101 && ptr[4] == 0 // "more"
			}
			contrast = isMore ? .more : .less
		} else {
			let prefersMore = window.matchMedia(prefersContrast(.more))
			contrast = prefersMore ? .more : .less
		}
		applyContrast(contrast)
	}

	private nonisolated func bindEvents() {
		for group in groups {
			let buttons = group.querySelectorAll(".button-group-button")
			for button in buttons {
				_ = button.addEventListener("button-group-click") { [self] (event: CallbackString) in
					// "increased" starts with 'i' (105)
					let isIncreased = event.detail.withCString { ptr in
						ptr[0] == 105
					}
					self.applyContrast(isIncreased ? .more : .less)
				}
			}
		}
	}

	private nonisolated func applyContrast(_ contrast: CSSPrefersContrast) {
		let htmlElement = document.querySelector("html")
		switch contrast {
		case .more:
			htmlElement?.dataset.contrast("more")
			localStorage.setItem("contrast", "more")
		case .less:
			htmlElement?.dataset.contrast("less")
			localStorage.setItem("contrast", "less")
		default:
			break
		}

		let selectedValue: String
		switch contrast {
		case .more: selectedValue = "increased"
		case .less: selectedValue = "standard"
		default: selectedValue = "standard"
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
