#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Combobox component following Wikimedia Codex design system specification
/// A Combobox is a text input with a dropdown menu of selectable options.
/// Combines a menu of selectable items with a text box that can accept arbitrary input.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/combobox.html
public struct ComboboxView: HTML {
	let id: String
	let name: String
	let menuItems: [MenuItemView.MenuItemData]
	let selectedValue: String
	let placeholder: String
	let startIcon: String?
	let disabled: Bool
	let status: ValidationStatus
	let visibleItemLimit: Int?
	let `class`: String

	public enum ValidationStatus: String, Sendable {
		case `default`
		case error
	}

	public init(
		id: String,
		name: String,
		menuItems: [MenuItemView.MenuItemData] = [],
		selectedValue: String = "",
		placeholder: String = "",
		startIcon: String? = nil,
		disabled: Bool = false,
		status: ValidationStatus = .default,
		visibleItemLimit: Int? = nil,
		class: String = ""
	) {
		self.id = id
		self.name = name
		self.menuItems = menuItems
		self.selectedValue = selectedValue
		self.placeholder = placeholder
		self.startIcon = startIcon
		self.disabled = disabled
		self.status = status
		self.visibleItemLimit = visibleItemLimit
		self.`class` = `class`
	}

	@CSSBuilder
	private func comboboxViewCSS() -> [CSS] {
		position(.relative)
		display(.inlineBlock)
		minWidth(px(256))
	}

	@CSSBuilder
	private func comboboxIndicatorCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		width(minSizeIconMedium)
		height(minSizeIconMedium)
		color(colorSubtle)
		fontSize(fontSizeXSmall12)
		pointerEvents(.none)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
	}

	public func render(indent: Int = 0) -> String {
		return div {
			// Integrate TextInputView for the input field
			div {
				TextInputView(
					id: id,
					name: name,
					placeholder: placeholder,
					value: selectedValue,
					type: .text,
					status: status == .error ? .error : .default,
					disabled: disabled,
					startIcon: startIcon
				)

				span { "▼" }
					.class("combobox-indicator")
					.ariaHidden(true)
					.style {
						comboboxIndicatorCSS()
					}
			}
			.class("combobox-input-wrapper")

			MenuView(
				menuItems: menuItems,
				selected: [selectedValue],
				expanded: false,
				visibleItemLimit: visibleItemLimit,
				class: "combobox-menu"
			) {
				// No results message
				"No results found"
			}
		}
		.class(`class`.isEmpty ? "combobox-view" : "combobox-view \(`class`)")
		.style {
			comboboxViewCSS()
		}
		.render(indent: indent)
	}
}

#endif
