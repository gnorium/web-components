#if SERVER

import CSSBuilder
import DesignTokens
import CSSOMBuilder
import DOMBuilder
import Foundation
import HTMLBuilder
import WebTypes

/// A Card groups information related to a single topic.
public struct CardView: HTMLContent {
	let url: String
	let icon: String?
	let thumbnail: Thumbnail?
	let forceThumbnail: Bool
	let customPlaceholderIcon: String?
	let titleContent: [DOMNode]
	let descriptionContent: [DOMNode]
	let supportingTextContent: [DOMNode]
	let `class`: String

	public struct Thumbnail: Sendable {
		let url: String
		let alt: String

		public init(url: String, alt: String = "") {
			self.url = url
			self.alt = alt
		}
	}

	public init(
		url: String = "",
		icon: String? = nil,
		thumbnail: Thumbnail? = nil,
		forceThumbnail: Bool = false,
		customPlaceholderIcon: String? = nil,
		class: String = "",
		@HTMLBuilder title: () -> [DOMNode],
		@HTMLBuilder description: () -> [DOMNode] = { [] },
		@HTMLBuilder supportingText: () -> [DOMNode] = { [] }
	) {
		self.url = url
		self.icon = icon
		self.thumbnail = thumbnail
		self.forceThumbnail = forceThumbnail
		self.customPlaceholderIcon = customPlaceholderIcon
		self.`class` = `class`
		self.titleContent = title()
		self.descriptionContent = description()
		self.supportingTextContent = supportingText()
	}

	@CSSBuilder
	private func cardViewCSS(_ isLink: Bool) -> [CSSRule] {
		display(.block)
		backgroundColor(backgroundColorBase)
		border(borderWidthBase, .solid, borderColorSubtle)
		borderRadius(borderRadiusBase)
		overflow(.hidden)
		boxShadow(boxShadowSmall)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

		if isLink {
			textDecoration(.none)
			cursor(cursorBase)

			pseudoClass(.hover) {
				borderColor(borderColorBlueHover).important()
				boxShadow(boxShadowMedium).important()
			}

			pseudoClass(.focus) {
				borderColor(borderColorBlueFocus).important()
				boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
				outline(px(1), .solid, .transparent).important()
			}

			pseudoClass(.active) {
				borderColor(borderColorBlueActive).important()
			}
		}
	}

	@CSSBuilder
	private func cardMediaCSS() -> [CSSRule] {
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		flexShrink(0)
		backgroundColor(backgroundColorNeutralSubtle)
	}

	@CSSBuilder
	private func cardThumbnailCSS() -> [CSSRule] {
		width(px(80))
		height(px(80))
		overflow(.hidden)
		borderRadius(borderRadiusBase)
		flexShrink(0)
	}

	@CSSBuilder
	private func cardThumbnailImageCSS() -> [CSSRule] {
		width(perc(100))
		height(perc(100))
		objectFit(.cover)
		display(.block)
	}

	@CSSBuilder
	private func cardThumbnailPlaceholderCSS() -> [CSSRule] {
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		width(perc(100))
		height(perc(100))
		backgroundColor(backgroundColorNeutralSubtle)
		color(colorPlaceholder)
		fontSize(fontSizeLarge18)
	}

	@CSSBuilder
	private func cardIconCSS() -> [CSSRule] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconMedium)
		height(sizeIconMedium)
		flexShrink(0)
		color(colorSubtle)
	}

	@CSSBuilder
	private func cardTextCSS(_ hasMedia: Bool) -> [CSSRule] {
		display(.flex)
		flexDirection(.column)
		gap(spacing16)
		padding(spacing12)
		flex(1)
		minWidth(0)

		if hasMedia {
			justifyContent(.flexStart)
		}
	}

	@CSSBuilder
	private func cardTitleCSS(_ isLink: Bool) -> [CSSRule] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeXXLarge24)
		fontWeight(fontWeightNormal)
		lineHeight(lineHeightSmall22)
		color(isLink ? colorBlue : colorBase)
		margin(0)
		wordWrap(.breakWord)

		if isLink {
			transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem).important()
		}
	}

	@CSSBuilder
	private func cardDescriptionCSS() -> [CSSRule] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(colorBase)
		margin(0)
	}

	@CSSBuilder
	private func cardSupportingTextCSS() -> [CSSRule] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeXSmall12)
		lineHeight(lineHeightSmall22)
		color(colorSubtle)
		margin(0)
	}

	@CSSBuilder
	private func cardContentWrapperCSS(_ hasMedia: Bool) -> [CSSRule] {
		display(.flex)
		alignItems(hasMedia ? .flexStart : .center)
		gap(spacing16)
		width(perc(100))
	}

	public func render() -> DOMNode {
		let hasDescription = !descriptionContent.isEmpty
		let hasSupportingText = !supportingTextContent.isEmpty
		let isLink = !url.isEmpty
		let hasThumbnail = thumbnail != nil || forceThumbnail
		let hasIcon = icon != nil
		let hasMedia = hasThumbnail || hasIcon
		let hasTitleOnly = !hasDescription && !hasSupportingText

		let cardContentElement: DOMNode = div {
			if hasThumbnail {
				div {
					if let thumb = thumbnail {
						img()
							.src(thumb.url)
							.alt(thumb.alt)
							.class("card-thumbnail-image")
							.style {
								cardThumbnailImageCSS()
							}
					} else {
						// Placeholder
						span { customPlaceholderIcon ?? "📷" }
							.class("card-thumbnail-placeholder")
							.ariaHidden(true)
							.style {
								cardThumbnailPlaceholderCSS()
							}
					}
				}
				.class("card-thumbnail")
				.style {
					cardThumbnailCSS()
				}
			} else if let iconValue = icon {
				span { iconValue }
					.class("card-icon")
					.ariaHidden(true)
					.style {
						cardIconCSS()
					}
			}

			div {
				span { titleContent }
					.class("card-title")
					.style {
						cardTitleCSS(isLink)
					}

				if hasDescription {
					div { descriptionContent }
						.class("card-description")
						.style {
							cardDescriptionCSS()
						}
				}

				if hasSupportingText {
					div { supportingTextContent }
						.class("card-supporting-text")
						.style {
							cardSupportingTextCSS()
						}
				}
			}
			.class("card-text")
			.style {
				cardTextCSS(hasMedia)
			}
		}
		.class("card-content-wrapper")
		.style {
			cardContentWrapperCSS(hasMedia && !hasTitleOnly)
		}
		.render()

		if isLink {
			return a { cardContentElement }
			.href(url)
			.class(`class`.isEmpty ? "card-view card-is-link" : "card-view card-is-link \(`class`)")
			.style {
				cardViewCSS(true)
			}
			.render()
		} else {
			return div { cardContentElement }
			.class(`class`.isEmpty ? "card-view" : "card-view \(`class`)")
			.style {
				cardViewCSS(false)
			}
			.render()
		}
	}
}

#endif
