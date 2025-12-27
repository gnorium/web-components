#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Accordion component following Wikimedia Codex design system specification
/// An expandable and collapsible section of content, often featured in a vertically stacked list.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/accordion.html
public struct AccordionView: HTML {
	let id: String
	let open: Bool
	let actionIcon: String?
	let actionAlwaysVisible: Bool
	let actionButtonLabel: String
	let separation: Separation
	let headingLevel: HeadingLevel
	let titleContent: [HTML]
	let descriptionContent: [HTML]
	let contentSlot: [HTML]
	let `class`: String

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
		class: String = "",
		@HTMLBuilder title: () -> [HTML],
		@HTMLBuilder description: () -> [HTML] = { [] },
		@HTMLBuilder content: () -> [HTML]
	) {
		self.id = id
		self.open = open
		self.actionIcon = actionIcon
		self.actionAlwaysVisible = actionAlwaysVisible
		self.actionButtonLabel = actionButtonLabel
		self.separation = separation
		self.headingLevel = headingLevel
		self.`class` = `class`
		self.titleContent = title()
		self.descriptionContent = description()
		self.contentSlot = content()
	}

	@CSSBuilder
	private func accordionViewCSS(_ separation: Separation) -> [CSS] {
		display(.block)

		if separation == .outline {
			border(borderWidthBase, .solid, borderColorSubtle)
			borderRadius(borderRadiusBase)
			padding(spacing4)
		}
	}

	@CSSBuilder
	private func accordionSummaryCSS(_ separation: Separation, _ hasAction: Bool) -> [CSS] {
		display(.flex)
		alignItems(.center)
		gap(spacing8)
		cursor(cursorBase)
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

		pseudoClass(.hover) {
			backgroundColor(backgroundColorInteractiveSubtleHover).important()
		}

		pseudoClass(.focus) {
			outline(px(2), .solid, borderColorProgressiveFocus).important()
			outlineOffset(px(1)).important()
		}
	}

	@CSSBuilder
	private func accordionExpandIconCSS() -> [CSS] {
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
	private func accordionHeaderWrapperCSS() -> [CSS] {
		display(.flex)
		flexDirection(.column)
		gap(spacing4)
		flex(1)
		minWidth(0)
	}

	@CSSBuilder
	private func accordionTitleCSS() -> [CSS] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightBold)
		lineHeight(lineHeightSmall22)
		color(colorBase)
		margin(0)
		wordWrap(.breakWord)
	}

	@CSSBuilder
	private func accordionDescriptionCSS() -> [CSS] {
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
		fontWeight(fontWeightNormal)
	}

	@CSSBuilder
	private func accordionActionButtonCSS(_ actionAlwaysVisible: Bool) -> [CSS] {
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
			outline(px(2), .solid, borderColorProgressiveFocus).important()
			outlineOffset(px(-2)).important()
		}
	}

	@CSSBuilder
	private func accordionContentCSS(_ separation: Separation) -> [CSS] {
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
	private func accordionDividerCSS() -> [CSS] {
		height(borderWidthBase)
		backgroundColor(borderColorSubtle)
		margin(spacing0)
		border(.none)
	}

	public func render(indent: Int = 0) -> String {
		let hasDescription = !descriptionContent.isEmpty
		let hasAction = actionIcon != nil

		// Render heading with appropriate level
		let titleElement: HTML
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
				span { "›" }
					.class("accordion-expand-icon")
					.ariaHidden(true)
					.style {
						accordionExpandIconCSS()
					}

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
		_ = details.on(.toggle) { [self] _ in
			let isOpen = details.hasAttribute(.open)

			// Rotate expand icon
			if let expandIcon = self.expandIcon {
				if isOpen {
					expandIcon.style.transform(rotate(deg(90)))
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
			_ = actionButton.on(.click) { [self] event in
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
