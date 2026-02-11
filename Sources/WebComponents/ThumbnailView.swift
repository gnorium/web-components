#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A visual element used to display a small preview of an image.
public struct ThumbnailView: HTMLProtocol {
	let src: String?
	let alt: String
	let placeholderIcon: String?
	let `class`: String

	public init(
		src: String? = nil,
		alt: String = "",
		placeholderIcon: String? = nil,
		class: String = ""
	) {
		self.src = src
		self.alt = alt
		self.placeholderIcon = placeholderIcon
		self.`class` = `class`
	}

	@CSSBuilder
	private func thumbnailViewCSS() -> [CSSProtocol] {
		display(.block)
		position(.relative)
		minWidth(size256)
		minHeight(size256)
		width(size256)
		height(size256)
		overflow(.hidden)
		borderRadius(borderRadiusBase)
		backgroundColor(backgroundColorNeutralSubtle)
		flexShrink(0)
	}

	@CSSBuilder
	private func thumbnailImageCSS() -> [CSSProtocol] {
		display(.block)
		width(perc(100))
		height(perc(100))
		objectFit(.cover)
		objectPosition("center")
	}

	@CSSBuilder
	private func thumbnailPlaceholderCSS() -> [CSSProtocol] {
		position(.absolute)
		insetBlockStart(0)
		insetInlineStart(0)
		width(perc(100))
		height(perc(100))
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		backgroundColor(backgroundColorNeutralSubtle)
	}

	@CSSBuilder
	private func thumbnailPlaceholderIconCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconMedium)
		height(sizeIconMedium)
		color(colorPlaceholder)
		fontSize(sizeIconMedium)
	}

	public func render(indent: Int = 0) -> String {
		let hasThumbnail = src != nil && !(src?.isEmpty ?? true)

		let container = span {
			if hasThumbnail, let src = src {
				if !alt.isEmpty {
					span {}
						.class("thumbnail-image")
						.style {
							backgroundImage(url(src))
						}
						.ariaLabel(alt)
						.style {
							thumbnailImageCSS()
						}
				} else {
					span {}
						.class("thumbnail-image")
						.style {
							backgroundImage(url(src))
						}
						.style {
							thumbnailImageCSS()
						}
				}
			} else {
				span {
					span {
						placeholderIcon ?? "🖼"
					}
					.class("thumbnail-placeholder-icon")
					.ariaHidden(true)
					.style {
						thumbnailPlaceholderIconCSS()
					}
				}
				.class("thumbnail-placeholder")
				.ariaHidden(true)
				.style {
					thumbnailPlaceholderCSS()
				}
			}
		}
		.class(`class`.isEmpty ? "thumbnail-view" : "thumbnail-view \(`class`)")

		return container.style {
			thumbnailViewCSS()
		}
		.render(indent: indent)
	}
}

#endif
