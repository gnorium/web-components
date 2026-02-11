#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A multi-line text input that allows manual resizing if needed.
public struct TextAreaView: HTMLProtocol {
	let id: String
	let name: String
	let placeholder: String
	let value: String
	let status: ValidationStatus
	let disabled: Bool
	let readonly: Bool
	let required: Bool
	let rows: Int
	let autosize: Bool
	let startIcon: String?
	let endIcon: String?
	let `class`: String

	public enum ValidationStatus: String, Sendable {
		case `default`
		case error
	}

	public init(
		id: String,
		name: String,
		placeholder: String = "",
		value: String = "",
		status: ValidationStatus = .default,
		disabled: Bool = false,
		readonly: Bool = false,
		required: Bool = false,
		rows: Int = 4,
		autosize: Bool = false,
		startIcon: String? = nil,
		endIcon: String? = nil,
		class: String = ""
	) {
		self.id = id
		self.name = name
		self.placeholder = placeholder
		self.value = value
		self.status = status
		self.disabled = disabled
		self.readonly = readonly
		self.required = required
		self.rows = rows
		self.autosize = autosize
		self.startIcon = startIcon
		self.endIcon = endIcon
		self.`class` = `class`
	}

	@CSSBuilder
	private func textAreaViewCSS(_ hasStartIcon: Bool, _ hasEndIcon: Bool) -> [CSSProtocol] {
		position(.relative)
		display(.inlineBlock)
		width(perc(100))

		if hasStartIcon || hasEndIcon {
			display(.flex)
			alignItems(.flexStart)
			gap(spacing8)
		}
	}

	@CSSBuilder
	private func textAreaInputCSS(_ disabled: Bool, _ readonly: Bool, _ status: ValidationStatus, _ autosize: Bool, _ hasStartIcon: Bool, _ hasEndIcon: Bool) -> [CSSProtocol] {
		width(perc(100))
		minHeight(px(rows * 24))
		padding(spacing12)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightSmall22)
		color(disabled ? colorDisabled : colorBase)
		backgroundColor(disabled ? backgroundColorDisabled : (readonly ? backgroundColorNeutralSubtle : backgroundColorBase))
		border(borderWidthBase, .solid, status == .error ? borderColorRed : (disabled ? borderColorDisabled : borderColorSubtle))
		borderRadius(borderRadiusBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		outline(.none)
		cursor(disabled ? cursorBaseDisabled : cursorBase)

		if autosize {
			resize(.none)
			overflow(.hidden)
		} else {
			resize(.vertical)
			overflowY(.auto)
		}

		if hasStartIcon {
			paddingInlineStart(calc(spacing12 + sizeIconMedium + spacing8)).important()
		}

		if hasEndIcon {
			paddingInlineEnd(calc(spacing12 + sizeIconMedium + spacing8)).important()
		}

		pseudoElement(.placeholder) {
			color(colorPlaceholder).important()
			opacity(opacityIconPlaceholder).important()
		}

		pseudoClass(.focus, not(.disabled), not(.readOnly)) {
			borderColor(borderColorBlueFocus).important()
			boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
		}

		pseudoClass(.hover, not(.disabled), not(.readOnly)) {
			borderColor(borderColorBase).important()
		}
	}

	@CSSBuilder
	private func textAreaIconCSS(_ isStartIcon: Bool) -> [CSSProtocol] {
		position(.absolute)
		top(spacing12)
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconMedium)
		height(sizeIconMedium)
		color(colorSubtle)
		pointerEvents(.none)

		if isStartIcon {
			left(spacing12)
		} else {
			right(spacing12)
		}
	}

	public func render(indent: Int = 0) -> String {
		let hasStartIcon = startIcon != nil
		let hasEndIcon = endIcon != nil

		if hasStartIcon || hasEndIcon {
			var textAreaInput = textarea { value }
				.id(id)
				.name(name)
				.placeholder(placeholder)
				.disabled(disabled)
				.readonly(readonly)
				.required(required)
				.rows(rows)
				.class("text-area-input")

			if autosize {
				textAreaInput = textAreaInput.data("autosize", "true")
			}

			textAreaInput = textAreaInput.style {
				textAreaInputCSS(disabled, readonly, status, autosize, hasStartIcon, hasEndIcon)
			}

			var container = div {
				if let icon = startIcon {
					span { icon }
						.class("text-area-start-icon")
						.ariaHidden(true)
						.style {
							textAreaIconCSS(true)
						}
				}

				textAreaInput

				if let icon = endIcon {
					span { icon }
						.class("text-area-end-icon")
						.ariaHidden(true)
						.style {
							textAreaIconCSS(false)
						}
				}
			}
			.class(`class`.isEmpty ? "text-area-view" : "text-area-view \(`class`)")

			if status == .error {
				container = container.data("status", "error")
			}

			return container.style {
				textAreaViewCSS(hasStartIcon, hasEndIcon)
			}
			.render(indent: indent)
		} else {
			var textAreaInput = textarea { value }
				.id(id)
				.name(name)
				.placeholder(placeholder)
				.disabled(disabled)
				.readonly(readonly)
				.required(required)
				.rows(rows)
				.class("text-area-input")

			if autosize {
				textAreaInput = textAreaInput.data("autosize", "true")
			}

			textAreaInput = textAreaInput.style {
				textAreaInputCSS(disabled, readonly, status, autosize, hasStartIcon, hasEndIcon)
			}

			var container = div {
				textAreaInput
			}
			.class(`class`.isEmpty ? "text-area-view" : "text-area-view \(`class`)")

			if status == .error {
				container = container.data("status", "error")
			}

			return container.style {
				textAreaViewCSS(hasStartIcon, hasEndIcon)
			}
			.render(indent: indent)
		}
	}
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

private class TextAreaInstance: @unchecked Sendable {
	private var textArea: Element
	private var input: Element?
	private var autosize: Bool = false

	init(textArea: Element) {
		self.textArea = textArea

		input = textArea.querySelector(".text-area-input")

		// Check if autosize is enabled
		if let autosizeAttr = textArea.querySelector(".text-area-input")?.getAttribute("data-autosize") {
			autosize = stringEquals(autosizeAttr, "true")
		}

		if autosize {
			bindAutosizeEvents()
			// Initial resize
			resizeToFit()
		}
	}

	private func bindAutosizeEvents() {
		guard let input else { return }

		// Resize on input
		_ = input.addEventListener(.input) { [self] _ in
			self.resizeToFit()
		}

		// Resize on window resize (in case of layout changes)
		window.addEventListener(.resize) { [self] _ in
			self.resizeToFit()
		}
	}

	private func resizeToFit() {
		guard let input = input else { return }

		// Reset height to auto to get the correct scrollHeight
		input.style.height(.auto)

		// Set height to scrollHeight to fit content
		let scrollHeight = input.scrollHeight
		input.style.height(px(scrollHeight))
	}
}

public class TextAreaHydration: @unchecked Sendable {
	private var instances: [TextAreaInstance] = []

	public init() {
		hydrateAllTextAreas()
	}

	private func hydrateAllTextAreas() {
		let allTextAreas = document.querySelectorAll(".text-area-view")

		for textArea in allTextAreas {
			let instance = TextAreaInstance(textArea: textArea)
			instances.append(instance)
		}
	}
}

#endif
