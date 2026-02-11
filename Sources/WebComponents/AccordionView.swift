#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct AccordionView: HTMLProtocol {
	let id: String
	let open: Bool
	let actionIcon: String?
	let actionAlwaysVisible: Bool
	let actionButtonLabel: String
	let separation: Separation
	let headingLevel: HeadingLevel
	let headerDirection: HeaderDirection
	let titleContent: [HTMLProtocol]
	let descriptionContent: [HTMLProtocol]
	let contentSlot: [HTMLProtocol]
	let `class`: String

	public enum HeaderDirection: Sendable {
		case column
		case row
	}

	public enum Separation: Sendable {
		case none
		case minimal
		case divider
		case outline

		var value: String {
			switch self {
			case .none: return "none"
			case .minimal: return "minimal"
			case .divider: return "divider"
			case .outline: return "outline"
			}
		}
	}

	public enum HeadingLevel: Sendable {
		case h1
		case h2
		case h3
		case h4
		case h5
		case h6

		var value: String {
			switch self {
			case .h1: return "h1"
			case .h2: return "h2"
			case .h3: return "h3"
			case .h4: return "h4"
			case .h5: return "h5"
			case .h6: return "h6"
			}
		}
	}

	public init(
		id: String,
		open: Bool = false,
		actionIcon: String? = nil,
		actionAlwaysVisible: Bool = false,
		actionButtonLabel: String = "",
		separation: Separation = .divider,
		headingLevel: HeadingLevel = .h3,
		headerDirection: HeaderDirection = .column,
		class: String = "",
		@HTMLBuilder title: () -> [HTMLProtocol],
		@HTMLBuilder description: () -> [HTMLProtocol] = { [] },
		@HTMLBuilder content: () -> [HTMLProtocol]
	) {
		self.id = id
		self.open = open
		self.actionIcon = actionIcon
		self.actionAlwaysVisible = actionAlwaysVisible
		self.actionButtonLabel = actionButtonLabel
		self.separation = separation
		self.headingLevel = headingLevel
		self.headerDirection = headerDirection
		self.`class` = `class`
		self.titleContent = title()
		self.descriptionContent = description()
		self.contentSlot = content()
	}

	@CSSBuilder
	private func accordionViewCSS(_ separation: Separation) -> [CSSProtocol] {
		display(.block)

		if separation == .outline {
			border(borderWidthBase, .solid, borderColorSubtle)
			borderRadius(borderRadiusBase)
			padding(spacing4)
		}
	}

	@CSSBuilder
	private func accordionSummaryCSS(_ separation: Separation, _ hasAction: Bool) -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		gap(spacing8)
		cursor(cursorBaseHover)
		listStyle(.none)
		userSelect(.none)

		if separation == .minimal {
			minHeight(minSizeInteractivePointer)
			padding(spacing4, spacing0)
		} else {
			padding(spacing12, spacing16)
		}

		if separation == .outline {
			borderRadius(borderRadiusBase)
		}

		pseudoElement(.marker) {
			display(.none).important()
		}

		pseudoElement(.webkitDetailsMarker) {
			display(.none).important()
		}

		pseudoClass(.focusVisible) {
			outline(px(2), .solid, borderColorBlueFocus).important()
			outlineOffset(px(1)).important()
		}

		pseudoClass(.focus) {
			outline(.none).important()
		}
	}

	@CSSBuilder
	private func accordionExpandIconCSS() -> [CSSProtocol] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		flexShrink(0)
		width(sizeIconMedium)
		height(sizeIconMedium)
		color(colorSubtle)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
	}

	@CSSBuilder
	private func accordionHeaderWrapperCSS() -> [CSSProtocol] {
		display(.flex)
		if headerDirection == .row {
			flexDirection(.row)
			alignItems(.center)
			gap(spacing8)
		} else {
			flexDirection(.column)
			gap(spacing4)
		}
		flex(1)
		minWidth(0)
	}

	@CSSBuilder
	private func accordionTitleCSS() -> [CSSProtocol] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightSemiBold)
		lineHeight(lineHeightSmall22)
		color(colorBase)
		margin(0)
		wordWrap(.breakWord)
	}

	@CSSBuilder
	private func accordionDescriptionCSS() -> [CSSProtocol] {
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
		fontWeight(fontWeightNormal)
	}

	@CSSBuilder
	private func accordionActionButtonCSS(_ actionAlwaysVisible: Bool) -> [CSSProtocol] {
		if actionAlwaysVisible {
			display(.inlineFlex)
		} else {
			display(.none)
		}

		alignItems(.center)
		justifyContent(.center)
		flexShrink(0)
		width(minSizeInteractivePointer)
		height(minSizeInteractivePointer)
		padding(0)
		backgroundColor(.transparent)
		border(.none)
		borderRadius(borderRadiusBase)
		color(colorSubtle)
		cursor(cursorBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

		pseudoClass(.hover) {
			backgroundColor(backgroundColorInteractiveSubtleHover).important()
			color(colorBase).important()
		}

		pseudoClass(.active) {
			backgroundColor(backgroundColorInteractiveSubtleActive).important()
		}

		pseudoClass(.focus) {
			outline(px(2), .solid, borderColorBlueFocus).important()
			outlineOffset(px(-2)).important()
		}
	}

	@CSSBuilder
	private func accordionContentCSS(_ separation: Separation) -> [CSSProtocol] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		lineHeight(lineHeightSmall22)
		color(colorBase)

		if separation == .minimal {
			padding(spacing12, spacing0)
		} else {
			padding(spacing16)
		}
	}

	@CSSBuilder
	private func accordionDividerCSS() -> [CSSProtocol] {
		height(borderWidthBase)
		backgroundColor(borderColorSubtle)
		margin(spacing0)
		border(.none)
	}

	public func render(indent: Int = 0) -> String {
		let hasDescription = !descriptionContent.isEmpty
		let hasAction = actionIcon != nil

		// Render heading with appropriate level
		let titleElement: HTMLProtocol
		switch headingLevel {
		case .h1:
			titleElement = h1 { titleContent }
				.class("accordion-title")
				.style { accordionTitleCSS() }
		case .h2:
			titleElement = h2 { titleContent }
				.class("accordion-title")
				.style { accordionTitleCSS() }
		case .h3:
			titleElement = h3 { titleContent }
				.class("accordion-title")
				.style { accordionTitleCSS() }
		case .h4:
			titleElement = h4 { titleContent }
				.class("accordion-title")
				.style { accordionTitleCSS() }
		case .h5:
			titleElement = h5 { titleContent }
				.class("accordion-title")
				.style { accordionTitleCSS() }
		case .h6:
			titleElement = h6 { titleContent }
				.class("accordion-title")
				.style { accordionTitleCSS() }
		}

		let detailsElement: HTMLDetailsElement = details {
			summary {
				div {
					titleElement

					if hasDescription {
						div { descriptionContent }
							.class("accordion-description")
							.style {
								accordionDescriptionCSS()
							}
					}
				}
				.class("accordion-header-wrapper")
				.style {
					accordionHeaderWrapperCSS()
				}

				if let icon = actionIcon {
					button {
						span { icon }
							.ariaHidden(true)
					}
					.type(.button)
					.class("accordion-action-button")
					.ariaLabel(actionButtonLabel)
					.style {
						accordionActionButtonCSS(actionAlwaysVisible)
					}
				}

				// Chevron icon at the end, rotates 180° when open
				span {
					IconView(
						icon: { size in [ExpandIconView(width: size, height: size)] },
						size: .medium
					)
				}
				.class("accordion-expand-icon")
				.style {
					display(.inlineFlex)
					alignItems(.center)
					justifyContent(.center)
					color(colorSubtle)
					transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
				}
			}
			.class("accordion-summary")
			.style {
				accordionSummaryCSS(separation, hasAction)
			}

			div { contentSlot }
				.class("accordion-content")
				.style {
					accordionContentCSS(separation)
				}
		}
		.open(open)
		.class("accordion-details")
		.id(id)

		if separation == .divider {
			return div {
				detailsElement

				hr()
				.class("accordion-divider")
				.ariaHidden(true)
				.style {
					accordionDividerCSS()
				}
			}
			.class(`class`.isEmpty ? "accordion-view" : "accordion-view \(`class`)")
			.data("separation", separation.value)
			.style {
				accordionViewCSS(separation)
			}
			.render(indent: indent)
		} else {
			return div {
				detailsElement
			}
			.class(`class`.isEmpty ? "accordion-view" : "accordion-view \(`class`)")
			.data("separation", separation.value)
			.style {
				accordionViewCSS(separation)
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

private class AccordionInstance: @unchecked Sendable {
	private var accordion: Element
	private var details: Element?
	private var summary: Element?
	private var actionButton: Element?
	private var expandIcon: Element?

	init(accordion: Element) {
		self.accordion = accordion

		details = accordion.querySelector(".accordion-details")
		summary = accordion.querySelector(".accordion-summary")
		actionButton = accordion.querySelector(".accordion-action-button")
		expandIcon = accordion.querySelector(".accordion-expand-icon")

		bindEvents()
	}

	private func bindEvents() {
		guard let details = details else { return }

		// Handle toggle event
		_ = details.addEventListener(.toggle) { [self] _ in
			let isOpen = details.hasAttribute(.open)

			// Rotate expand icon 180° when open (chevron points up)
			if let expandIcon = self.expandIcon {
				if isOpen {
					expandIcon.style.transform(rotate(deg(180)))
				} else {
					expandIcon.style.transform(rotate(deg(0)))
				}
			}

			// Show/hide action button if not always visible
			if let actionButton = self.actionButton {
				let displayValue = actionButton.getAttribute(.style) ?? ""
				let alwaysVisible = !stringContains(displayValue, "display: none")
				if !alwaysVisible {
					if isOpen {
						actionButton.style.display(.inlineFlex)
					} else {
						actionButton.style.display(.none)
					}
				}
			}

			// Dispatch custom toggle event
			let detailValue: String
			if isOpen {
				detailValue = "true"
			} else {
				detailValue = "false"
			}
			let event = CustomEvent(type: "accordion-toggle", detail: detailValue)
			self.accordion.dispatchEvent(event)
		}

		// Handle action button click
		if let actionButton = actionButton {
			_ = actionButton.addEventListener(.click) { [self] event in
				event.stopPropagation()
				let clickEvent = CustomEvent(type: "accordion-action-click", detail: "")
				self.accordion.dispatchEvent(clickEvent)
			}
		}
	}
}

public class AccordionHydration: @unchecked Sendable {
	private var instances: [AccordionInstance] = []

	public init() {
		hydrateAllAccordions()
	}

	private func hydrateAllAccordions() {
		let allAccordions = document.querySelectorAll(".accordion-view")

		for accordion in allAccordions {
			let instance = AccordionInstance(accordion: accordion)
			instances.append(instance)
		}
	}
}

#endif
