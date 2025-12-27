#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Popover component following Wikimedia Codex design system specification
/// A non-disruptive container that is overlaid on a web page or app, positioned near its trigger.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/popover.html
public struct PopoverView: HTML {
	let open: Bool
	let title: String
	let icon: String?
	let useCloseButton: Bool
	let closeButtonLabel: String
	let primaryAction: PrimaryAction?
	let defaultAction: DefaultAction?
	let stackedActions: Bool
	let renderInPlace: Bool
	let placement: Placement
	let headerContent: [HTML]
	let bodyContent: [HTML]
	let footerContent: [HTML]
	let `class`: String
	
	public enum Placement: String, Sendable {
		case top
		case topStart = "top-start"
		case topEnd = "top-end"
		case bottom
		case bottomStart = "bottom-start"
		case bottomEnd = "bottom-end"
		case left
		case leftStart = "left-start"
		case leftEnd = "left-end"
		case right
		case rightStart = "right-start"
		case rightEnd = "right-end"
	}

	public struct PrimaryAction: Sendable {
		let label: String
		let type: ActionType

		public enum ActionType: String, Sendable {
			case progressive
			case destructive
		}

		public init(label: String, type: ActionType = .progressive) {
			self.label = label
			self.type = type
		}
	}

	public struct DefaultAction: Sendable {
		let label: String

		public init(label: String) {
			self.label = label
		}
	}

	public init(
		open: Bool = false,
		title: String = "",
		icon: String? = nil,
		useCloseButton: Bool = false,
		closeButtonLabel: String = "Close",
		primaryAction: PrimaryAction? = nil,
		defaultAction: DefaultAction? = nil,
		stackedActions: Bool = false,
		renderInPlace: Bool = false,
		placement: Placement = .bottom,
		class: String = "",
		@HTMLBuilder header: () -> [HTML] = { [] },
		@HTMLBuilder body: () -> [HTML] = { [] },
		@HTMLBuilder footer: () -> [HTML] = { [] }
	) {
		self.open = open
		self.title = title
		self.icon = icon
		self.useCloseButton = useCloseButton
		self.closeButtonLabel = closeButtonLabel
		self.primaryAction = primaryAction
		self.defaultAction = defaultAction
		self.stackedActions = stackedActions
		self.renderInPlace = renderInPlace
		self.placement = placement
		self.`class` = `class`
		self.headerContent = header()
		self.bodyContent = body()
		self.footerContent = footer()
	}

	@CSSBuilder
	private func popoverViewCSS(_ open: Bool) -> [CSS] {
		position(.absolute)
		backgroundColor(backgroundColorBase)
		border(borderWidthBase, .solid, borderColorSubtle)
		borderRadius(borderRadiusBase)
		boxShadow(boxShadowOutsetMediumAround)
		zIndex(zIndexPopover)
		minWidth(px(256))
		maxWidth(px(320))
		padding(0)

		if !open {
			display(.none)
		}
	}

	@CSSBuilder
	private func popoverArrowCSS(_ placement: Placement) -> [CSS] {
		position(.absolute)
		width(px(12))
		height(px(12))
		backgroundColor(backgroundColorBase)
		border(borderWidthBase, .solid, borderColorSubtle)
		transform("rotate(45deg)")

		switch placement {
			case .top, .topStart, .topEnd:
				bottom(px(-7))
				borderTop(.none)
				borderLeft(.none)
			case .bottom, .bottomStart, .bottomEnd:
				top(px(-7))
				borderBottom(.none)
				borderRight(.none)
			case .left, .leftStart, .leftEnd:
				right(px(-7))
				borderLeft(.none)
				borderBottom(.none)
			case .right, .rightStart, .rightEnd:
				left(px(-7))
				borderTop(.none)
				borderRight(.none)
		}

		// Horizontal positioning for arrow
		switch placement {
		case .top, .bottom:
			left(perc(50))
			marginLeft(px(-6))
		case .topStart, .bottomStart:
			left(spacing16)
		case .topEnd, .bottomEnd:
			right(spacing16)
		case .left, .right:
			top(perc(50))
			marginTop(px(-6))
		case .leftStart, .rightStart:
			top(spacing16)
		case .leftEnd, .rightEnd:
			bottom(spacing16)
		}
	}

	@CSSBuilder
	private func popoverHeaderCSS(_ hasCustomHeader: Bool) -> [CSS] {
		display(.flex)
		alignItems(.center)
		gap(spacing8)
		padding(spacing12)
		borderBottom(borderWidthBase, .solid, borderColorSubtle)

		if hasCustomHeader {
			justifyContent(.spaceBetween)
		}
	}

	@CSSBuilder
	private func popoverHeaderContentCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		gap(spacing8)
		flex(1)
		minWidth(0)
	}

	@CSSBuilder
	private func popoverIconCSS() -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconMedium)
		height(sizeIconMedium)
		flexShrink(0)
		color(colorSubtle)
		fontSize(fontSizeLarge18)
	}

	@CSSBuilder
	private func popoverTitleCSS() -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightBold)
		lineHeight(lineHeightSmall22)
		color(colorBase)
		margin(0)
		flex(1)
		minWidth(0)
	}

	@CSSBuilder
	private func popoverBodyCSS() -> [CSS] {
		padding(spacing12)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightMedium26)
		color(colorBase)
	}

	@CSSBuilder
	private func popoverFooterCSS(_ hasActions: Bool, _ stackedActions: Bool) -> [CSS] {
		if hasActions {
			display(.flex)
			gap(spacing8)
			padding(spacing12)
			borderTop(borderWidthBase, .solid, borderColorSubtle)

			if stackedActions {
				flexDirection(.column)
			} else {
				flexDirection(.row)
				justifyContent(.flexStart)
			}
		} else {
			padding(spacing12)
			borderTop(borderWidthBase, .solid, borderColorSubtle)
		}
	}

	@CSSBuilder
	private func popoverPrimaryButtonCSS(_ stackedActions: Bool) -> [CSS] {
		if stackedActions {
			// Primary button on top in stacked layout
			order(-1)
		}
	}

	public func render(indent: Int = 0) -> String {
		let hasCustomHeader = !headerContent.isEmpty
		let hasIcon = icon != nil
		let hasTitle = !title.isEmpty
		let hasActions = primaryAction != nil || defaultAction != nil
		let hasFooterContent = !footerContent.isEmpty

		return div {
			// Arrow
			div {}
				.class("popover-arrow")
				.style {
					popoverArrowCSS(placement)
				}

			// Header
			if hasCustomHeader || hasIcon || hasTitle || useCloseButton {
				div {
					if hasCustomHeader {
						headerContent
					} else {
						div {
							if let iconValue = icon {
								span { iconValue }
									.class("popover-icon")
									.ariaHidden(true)
									.style {
										popoverIconCSS()
									}
							}

							if hasTitle {
								h2 { title }
									.class("popover-title")
									.style {
										popoverTitleCSS()
									}
							}
						}
						.class("popover-header-content")
						.style {
							popoverHeaderContentCSS()
						}
					}

					if useCloseButton {
						button {
							span { "×" }
								.ariaHidden(true)
						}
						.type(.button)
						.class("popover-close-button")
						.ariaLabel(closeButtonLabel)
					}
				}
				.class("popover-header")
				.style {
					popoverHeaderCSS(hasCustomHeader)
				}
			}

			// Body
			div {
				bodyContent
			}
			.class("popover-body")
			.style {
				popoverBodyCSS()
			}

			// Footer
			if hasActions || hasFooterContent {
				div {
					if hasFooterContent {
						footerContent
					} else {
						if let defAction = defaultAction {
							div {
								ButtonView(
									label: defAction.label,
									action: .default,
									weight: .normal
								)
							}
							.class("popover-default-button")
						}

						if let primAction = primaryAction {
							div {
								ButtonView(
									label: primAction.label,
									action: primAction.type == .progressive ? .progressive : .destructive,
									weight: .primary
								)
							}
							.class("popover-primary-button")
						}
					}
				}
				.class("popover-footer")
				.style {
					popoverFooterCSS(hasActions, stackedActions)
				}
			}
		}
		.class(`class`.isEmpty ? "popover-view" : "popover-view \(`class`)")
		.data("open", open ? true : false)
		.data("placement", placement.rawValue)
		.data("render-in-place", renderInPlace ? true : false)
		.data("stacked-actions", stackedActions ? true : false)
		.role(.dialog)
		.ariaModal(false)
		.style {
			popoverViewCSS(open)
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

private class PopoverInstance: @unchecked Sendable {
	private var popover: Element
	private var closeButton: Element?
	private var primaryButton: Element?
	private var defaultButton: Element?
	private var isOpen: Bool = false

	init(popover: Element) {
		self.popover = popover

		closeButton = popover.querySelector(".popover-close-button")
		primaryButton = popover.querySelector(".popover-primary-button")
		defaultButton = popover.querySelector(".popover-default-button")

		// Get initial open state
		if let openAttr = popover.getAttribute("data-open") {
			isOpen = stringEquals(openAttr, "true")
		}

		// Apply stacked actions styling
		if let stackedAttr = popover.getAttribute("data-stacked-actions"), stringEquals(stackedAttr, "true") {
			if let primBtn = primaryButton {
				primBtn.style.order(-1)
			}
		}

		bindEvents()
		positionPopover()
	}

	private func bindEvents() {
		// Close button
		if let closeBtn = closeButton {
			_ = closeBtn.on(.click) { [self] _ in
				self.closePopover()
			}
		}

		// Primary action button
		if let primBtn = primaryButton {
			_ = primBtn.on(.click) { [self] _ in
				let event = CustomEvent(type: "popover-primary", detail: "")
				self.popover.dispatchEvent(event)
			}
		}

		// Default action button
		if let defBtn = defaultButton {
			_ = defBtn.on(.click) { [self] _ in
				let event = CustomEvent(type: "popover-default", detail: "")
				self.popover.dispatchEvent(event)
			}
		}

		// Keyboard navigation
		_ = popover.on(.keydown) { [self] (event: CallbackString) in
			self.handleKeydown(event)
		}

		// Click outside to close
		_ = document.on(.click) { [self] event in
			guard let target = event.target else { return }

			// Check if click is outside popover
			if self.isOpen && !self.popover.contains(target) {
				self.closePopover()
			}
		}

		// Focus trap - Tab key handling
		_ = popover.on(.keydown) { [self] (event: CallbackString) in
			event.withCString { eventPtr in
				let key = String(cString: eventPtr)

				if stringEquals(key, "Tab") {
					self.handleTabKey(event)
				}
			}
		}
	}

	private func positionPopover() {
		// Position popover relative to anchor
		// This would typically use a positioning library or custom logic
		// For now, CSS handles basic positioning
	}

	private func closePopover() {
		popover.dataset["open"] = "false"
		isOpen = false

		// Dispatch close event
		let event = CustomEvent(type: "popover-close", detail: "")
		popover.dispatchEvent(event)
	}

	private func handleKeydown(_ event: CallbackString) {
		event.withCString { eventPtr in
			let key = String(cString: eventPtr)

			if stringEquals(key, "Escape") {
				closePopover()
			}
		}
	}

	private func handleTabKey(_ event: CallbackString) {
		// Get all focusable elements within popover
		let focusableElements = popover.querySelectorAll(
			"button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex=\"-1\"])"
		)

		guard !focusableElements.isEmpty else { return }

		let firstElement = focusableElements[0]
		let lastElement = focusableElements[focusableElements.count - 1]

		// Check if Shift is pressed (would need event.shiftKey in real implementation)
		// For now, basic Tab handling
		guard let activeElement = document.activeElement else { return }

		// If Tab on last element, focus first
		if activeElement.id == lastElement.id {
			event.preventDefault()
			firstElement.focus()
		}
	}
}

public class PopoverHydration: @unchecked Sendable {
	private var instances: [PopoverInstance] = []

	public init() {
		hydrateAllPopovers()
	}

	private func hydrateAllPopovers() {
		let allPopovers = document.querySelectorAll(".popover-view")

		for popover in allPopovers {
			let instance = PopoverInstance(popover: popover)
			instances.append(instance)
		}
	}
}

#endif
