#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Dialog component following Wikimedia Codex design system specification
/// A Dialog is a container that is overlaid on a web page or app in order to present necessary information and tasks.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/dialog.html
public struct DialogView: HTML {
	let open: Bool
	let title: String
	let subtitle: String?
	let hideTitle: Bool
	let hideHeader: Bool
	let useCloseButton: Bool
	let closeButtonLabel: String
	let primaryAction: PrimaryAction?
	let defaultAction: DefaultAction?
	let stackedActions: Bool
	let headerContent: [HTML]
	let bodyContent: [HTML]
	let footerContent: [HTML]
	let footerTextContent: [HTML]
	let `class`: String

	public struct PrimaryAction: Sendable {
		let label: String
		let type: ActionType
		let disabled: Bool

		public enum ActionType: String, Sendable {
			case progressive
			case destructive
		}

		public init(label: String, type: ActionType = .progressive, disabled: Bool = false) {
			self.label = label
			self.type = type
			self.disabled = disabled
		}
	}

	public struct DefaultAction: Sendable {
		let label: String
		let disabled: Bool

		public init(label: String, disabled: Bool = false) {
			self.label = label
			self.disabled = disabled
		}
	}

	public init(
		open: Bool = false,
		title: String,
		subtitle: String? = nil,
		hideTitle: Bool = false,
		hideHeader: Bool = false,
		useCloseButton: Bool = false,
		closeButtonLabel: String = "Close",
		primaryAction: PrimaryAction? = nil,
		defaultAction: DefaultAction? = nil,
		stackedActions: Bool = false,
		class: String = "",
		@HTMLBuilder header: () -> [HTML] = { [] },
		@HTMLBuilder body: () -> [HTML],
		@HTMLBuilder footer: () -> [HTML] = { [] },
		@HTMLBuilder footerText: () -> [HTML] = { [] }
	) {
		self.open = open
		self.title = title
		self.subtitle = subtitle
		self.hideTitle = hideTitle
		self.hideHeader = hideHeader
		self.useCloseButton = useCloseButton
		self.closeButtonLabel = closeButtonLabel
		self.primaryAction = primaryAction
		self.defaultAction = defaultAction
		self.stackedActions = stackedActions
		self.`class` = `class`
		self.headerContent = header()
		self.bodyContent = body()
		self.footerContent = footer()
		self.footerTextContent = footerText()
	}

	@CSSBuilder
	private func dialogBackdropCSS() -> [CSS] {
		position(.fixed)
		top(0)
		left(0)
		right(0)
		bottom(0)
		width(perc(100))
		height(perc(100))
		backgroundColor(backgroundColorBackdropDark)
		zIndex(200)
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		padding(spacing16)
	}

	@CSSBuilder
	private func dialogShellCSS() -> [CSS] {
		position(.relative)
		display(.flex)
		flexDirection(.column)
		width(min(calc(vw(100) - px(60)), px(900)))
		backgroundColor(backgroundColorBase)
		borderRadius(borderRadiusBase)
		boxShadow(boxShadowOutsetMediumAround)
		overflow(.hidden)
	}

	@CSSBuilder
	private func dialogHeaderCSS(_ hasCustomHeader: Bool) -> [CSS] {
		if !hasCustomHeader {
			display(.flex)
			flexDirection(.column)
			gap(spacing4)
			padding(spacing20, spacing24)
			borderBottom(borderWidthBase, .solid, borderColorSubtle)
		}
	}

	@CSSBuilder
	private func dialogHeaderTitleGroupCSS() -> [CSS] {
		display(.flex)
		alignItems(.flexStart)
		gap(spacing16)
		minWidth(0)
	}

	@CSSBuilder
	private func dialogHeaderTextCSS() -> [CSS] {
		display(.flex)
		flexDirection(.column)
		gap(spacing4)
		flex(1)
		minWidth(0)
	}

	@CSSBuilder
	private func dialogHeaderTitleCSS(_ hideTitle: Bool) -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeLarge18)
		fontWeight(fontWeightBold)
		lineHeight(lineHeightSmall22)
		color(colorBase)
		margin(0)
		wordWrap(.breakWord)

		if hideTitle {
			position(.absolute)
			width(px(1))
			height(px(1))
			margin(px(-1))
			padding(0)
			overflow(.hidden)
			clip(rect(0, 0, 0, 0))
			whiteSpace(.nowrap)
			borderWidth(0)
		}
	}

	@CSSBuilder
	private func dialogHeaderSubtitleCSS() -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeSmall14)
		fontWeight(fontWeightNormal)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
		margin(0)
		wordWrap(.breakWord)
	}

	@CSSBuilder
	private func dialogCloseButtonCSS() -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		minWidth(minSizeInteractivePointer)
		minHeight(minSizeInteractivePointer)
		padding(0)
		backgroundColor(.transparent)
		border(.none)
		borderRadius(borderRadiusBase)
		color(colorSubtle)
		cursor(cursorBaseHover)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

		pseudoClass(.hover) {
			backgroundColor(backgroundColorInteractiveSubtleHover).important()
			color(colorBase).important()
			cursor(cursorBaseHover).important()
		}

		pseudoClass(.active) {
			backgroundColor(backgroundColorInteractiveSubtleActive).important()
			color(colorBase).important()
		}

		pseudoClass(.focus) {
			backgroundColor(backgroundColorInteractiveSubtleHover).important()
			color(colorBase).important()
			outline(px(2), .solid, borderColorProgressiveFocus).important()
			outlineOffset(px(-2)).important()
		}
	}

	@CSSBuilder
	private func dialogBodyCSS() -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightMedium26)
		color(colorBase)
		padding(spacing8)
		overflowY(.auto)
		flex(1)
	}

	@CSSBuilder
	private func dialogFooterCSS(_ hasCustomFooter: Bool, _ hasFooterText: Bool) -> [CSS] {
		if !hasCustomFooter {
			display(.flex)
			flexDirection(.column)
			gap(spacing12)
			padding(spacing20, spacing24)
			borderTop(borderWidthBase, .solid, borderColorSubtle)

			if !hasFooterText {
				flexDirection(.row)
				alignItems(.center)
				justifyContent(.flexEnd)
			}
		}
	}

	@CSSBuilder
	private func dialogFooterTextCSS() -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
		margin(0)
	}

	@CSSBuilder
	private func dialogFooterActionsCSS(_ stackedActions: Bool) -> [CSS] {
		display(.flex)
		gap(spacing12)

		if stackedActions {
			flexDirection(.columnReverse)
			alignItems(.stretch)
		} else {
			flexDirection(.rowReverse)
			alignItems(.center)
			justifyContent(.flexStart)
		}
	}

	public func render(indent: Int = 0) -> String {
		let hasCustomHeader = !headerContent.isEmpty
		let hasCustomFooter = !footerContent.isEmpty
		let hasFooterText = !footerTextContent.isEmpty
		let hasActions = primaryAction != nil || defaultAction != nil

		// Default header (when no custom header provided)
		let defaultHeader: HTML = div {
			div {
				div {
					h2 { title }
						.class("dialog-header-title")
						.id("dialog-title")
						.style {
							dialogHeaderTitleCSS(hideTitle)
						}

					if let subtitleText = subtitle {
						p { subtitleText }
							.class("dialog-header-subtitle")
							.style {
								dialogHeaderSubtitleCSS()
							}
					}
				}
				.class("dialog-header-text")
				.style {
					dialogHeaderTextCSS()
				}

				if useCloseButton {
					button {
						span { "×" }
							.ariaHidden(true)
							.style {
								fontSize(fontSizeXXLarge24)
								lineHeight(1)
							}
					}
					.type(.button)
					.class("dialog-close-button")
					.ariaLabel(closeButtonLabel)
					.style {
						dialogCloseButtonCSS()
					}
				}
			}
			.class("dialog-header-title-group")
			.style {
				dialogHeaderTitleGroupCSS()
			}
		}
		.class("dialog-header")
		.style {
			dialogHeaderCSS(hasCustomHeader)
		}

		// Default footer (when no custom footer provided)
		let defaultFooter: HTML = div {
			if hasFooterText {
				div { footerTextContent }
					.class("dialog-footer-text")
					.style {
						dialogFooterTextCSS()
					}
			}

			if hasActions {
				div {
					// Default action button (comes second visually, but first in DOM for stacked)
					if let defAction = defaultAction {
						div {
							ButtonView(
								label: defAction.label,
								action: .default,
								weight: .normal,
								disabled: defAction.disabled
							)
						}
						.class("dialog-default-button")
					}

					// Primary action button (comes first visually, but second in DOM for stacked)
					if let primAction = primaryAction {
						div {
							ButtonView(
								label: primAction.label,
								action: primAction.type == .progressive ? .progressive : .destructive,
								weight: .primary,
								disabled: primAction.disabled
							)
						}
						.class("dialog-primary-button")
					}
				}
				.class("dialog-footer-actions")
				.style {
					dialogFooterActionsCSS(stackedActions)
				}
			}
		}
		.class("dialog-footer")
		.style {
			dialogFooterCSS(hasCustomFooter, hasFooterText)
		}

		return div {
			div {
				// Header
				if !hideHeader {
					if hasCustomHeader {
						headerContent
					} else {
						defaultHeader
					}
				}

				// Body
				div { bodyContent }
					.class("dialog-body")
					.style {
						dialogBodyCSS()
					}

				// Footer
				if hasCustomFooter {
					footerContent
				} else if hasFooterText || hasActions {
					defaultFooter
				}
			}
			.class("dialog-shell")
			.role(.dialog)
			.ariaModal(true)
			.ariaLabelledby("dialog-title")
			.style {
				dialogShellCSS()
			}
		}
		.class(`class`.isEmpty ? "dialog-view dialog-backdrop" : "dialog-view dialog-backdrop \(`class`)")
		.data("open", open ? "true" : "false")
		.style {
			dialogBackdropCSS()

			if !open {
				display(.none).important()
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

public class DialogHydration: @unchecked Sendable {
	private var instances: [Int32: DialogInstance] = [:]

	public init() {
		hydrateAllDialogs()
		hydrateTriggers()
	}

	private func hydrateAllDialogs() {
		let allDialogs = document.querySelectorAll(".dialog-view")

		for dialog in allDialogs {
			let instance = DialogInstance(dialog: dialog)
			let id = dialog.id
			if id > 0 {
				instances[id] = instance
			}
		}
	}

	private func hydrateTriggers() {
		let triggers = document.querySelectorAll("[data-dialog-trigger]")

		for trigger in triggers {
			_ = trigger.addEventListener(.click) { event in
				// Find the closest element with the data attribute (in case click target is a child span/icon)
				guard let targetElement = event.target?.closest("[data-dialog-trigger]"),
				      let dialogIdStr = targetElement.dataset["dialogTrigger"],
				      let dialogId = safeParseInt(dialogIdStr),
				      let instance = self.instances[Int32(dialogId)] else {
					return
				}

				instance.openDialog()
			}
		}
	}
}

private class DialogInstance: @unchecked Sendable {
	private var dialog: Element
	private var closeButton: Element?
	private var primaryButton: Element?
	private var defaultButton: Element?

	init(dialog: Element) {
		self.dialog = dialog

		closeButton = dialog.querySelector(".dialog-close-button")
		primaryButton = dialog.querySelector(".dialog-primary-button")
		defaultButton = dialog.querySelector(".dialog-default-button")

		bindEvents()
	}

	private func bindEvents() {
		// Close button
		if let closeButton = closeButton {
			_ = closeButton.addEventListener(.click) { [self] event in
				event.stopPropagation()
				self.closeDialog()
			}
		}

		// Backdrop click to close
		_ = dialog.addEventListener(.click) { [self] event in
			// Only close if clicking directly on backdrop (not on dialog shell)
			if let target = event.target, stringEquals(target.className, "dialog-view dialog-backdrop") || stringContains(target.className, "dialog-backdrop") {
				self.closeDialog()
			}
		}

		// Prevent clicks inside dialog shell from closing
		if let shell = dialog.querySelector(".dialog-shell") {
			_ = shell.addEventListener(.click) { event in
				event.stopPropagation()
			}
		}

		// ESC key to close
		_ = document.addEventListener(.keydown) { [self] event in
			let key = event.key
			if stringEquals(key, "Escape") {
				if let isOpen = self.dialog.dataset["open"], stringEquals(isOpen, "true") {
					self.closeDialog()
				}
			}
		}

		// Primary action button
		if let primaryButton = primaryButton {
			_ = primaryButton.addEventListener(.click) { [self] event in
				event.stopPropagation()
				let customEvent = CustomEvent(type: "dialog-primary", detail: "")
				self.dialog.dispatchEvent(customEvent)
			}
		}

		// Default action button
		if let defaultButton = defaultButton {
			_ = defaultButton.addEventListener(.click) { [self] event in
				event.stopPropagation()
				let customEvent = CustomEvent(type: "dialog-default", detail: "")
				self.dialog.dispatchEvent(customEvent)
			}
		}
	}

	private func closeDialog() {
		dialog.dataset["open"] = "false"
		dialog.style.display(.none)

		// Restore body scroll
		document.body.style.overflow(.auto)

		// Dispatch close event
		let event = CustomEvent(type: "dialog-close", detail: "")
		dialog.dispatchEvent(event)
	}

	public func openDialog() {
		dialog.dataset["open"] = "true"
		dialog.style.display(.flex)

		// Prevent body scroll
		document.body.style.overflow(.hidden)

		// Dispatch open event
		let event = CustomEvent(type: "dialog-open", detail: "")
		dialog.dispatchEvent(event)
	}
}

#endif
