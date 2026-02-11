#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// A list of links to the parent pages of the current page in hierarchical order.
public struct BreadcrumbView: HTMLProtocol {
	let items: [BreadcrumbItem]
	let truncateLength: Int
	let maxVisible: Int
	let `class`: String

	public struct BreadcrumbItem: Sendable {
		public let text: String
		public let url: String?

		public init(text: String, url: String? = nil) {
			self.text = text
			self.url = url
		}
	}

	public init(
		items: [BreadcrumbItem],
		truncateLength: Int = 40,
		maxVisible: Int = 6,
		class: String = ""
	) {
		self.items = items
		self.truncateLength = truncateLength
		self.maxVisible = maxVisible
		self.`class` = `class`
	}

	@CSSBuilder
	private func breadcrumbViewCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		flexWrap(.wrap)
		gap(spacing4)
		fontFamily(typographyFontSans)
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightXSmall20)
		color(colorSubtle)
	}

	@CSSBuilder
	private func breadcrumbItemCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		gap(spacing4)
	}

	@CSSBuilder
	private func breadcrumbLinkCSS() -> [CSSProtocol] {
		color(colorBlue)
		textDecoration(.none)
		maxWidth(px(350))
		overflow(.hidden)
		textOverflow(.ellipsis)
		whiteSpace(.nowrap)

		pseudoClass(.hover) {
			textDecoration(.underline).important()
		}

		pseudoClass(.focus) {
			outline(borderWidthThick, .solid, borderColorBlue).important()
			outlineOffset(px(1)).important()
			borderRadius(borderRadiusBase).important()
		}
	}

	@CSSBuilder
	private func breadcrumbCurrentCSS() -> [CSSProtocol] {
		color(colorBase)
		fontWeight(fontWeightNormal)
		maxWidth(px(350))
		overflow(.hidden)
		textOverflow(.ellipsis)
		whiteSpace(.nowrap)
	}

	@CSSBuilder
	private func breadcrumbSeparatorCSS() -> [CSSProtocol] {
		color(colorSubtle)
		userSelect(.none)
	}

	@CSSBuilder
	private func breadcrumbOverflowCSS() -> [CSSProtocol] {
		display(.inlineFlex)
		alignItems(.center)
		gap(spacing4)
	}

	public func render(indent: Int = 0) -> String {
		let visibleItems: [BreadcrumbItem]
		let overflowItems: [BreadcrumbItem]

		if items.count > maxVisible {
			visibleItems = [items[0]] + items.suffix(maxVisible - 1)
			overflowItems = Array(items[1..<(items.count - (maxVisible - 1))])
		} else {
			visibleItems = items
			overflowItems = []
		}

		let truncateText: (String) -> String = { text in
			if text.count > truncateLength {
				return String(text.prefix(truncateLength)) + "…"
			}
			return text
		}

		return nav {
			ol {
				for (index, item) in visibleItems.enumerated() {
					li {
						if index == 0 && !overflowItems.isEmpty {
							// First item
							if let url = item.url {
								a { truncateText(item.text) }
									.href(url)
									.class("breadcrumb-link")
									.style {
										breadcrumbLinkCSS()
									}
							} else {
								span { truncateText(item.text) }
									.class("breadcrumb-current")
									.style {
										breadcrumbCurrentCSS()
									}
							}

							span { "›" }
								.class("breadcrumb-separator")
								.ariaHidden(true)
								.style {
									breadcrumbSeparatorCSS()
								}

							// Overflow menu
							span {
								MenuButtonView(
									buttonLabel: "…",
									menuItems: overflowItems.map { overflowItem in
										MenuButtonView.MenuItem(
											value: overflowItem.url ?? "",
											label: overflowItem.text
										)
									}
								)
							}
							.class("breadcrumb-overflow")
							.style {
								breadcrumbOverflowCSS()
							}
						} else {
							// Regular item or current page
							let isLast = index == visibleItems.count - 1

							if isLast {
								span { truncateText(item.text) }
									.class("breadcrumb-current")
									.ariaCurrent(.page)
									.style {
										breadcrumbCurrentCSS()
									}
							} else {
								if let url = item.url {
									a { truncateText(item.text) }
										.href(url)
										.class("breadcrumb-link")
										.style {
											breadcrumbLinkCSS()
										}
								} else {
									span { truncateText(item.text) }
										.class("breadcrumb-current")
										.style {
											breadcrumbCurrentCSS()
										}
								}
							}

							if !isLast {
								span { "›" }
									.class("breadcrumb-separator")
									.ariaHidden(true)
									.style {
										breadcrumbSeparatorCSS()
									}
							}
						}
					}
					.class("breadcrumb-item")
					.style {
						breadcrumbItemCSS()
					}
				}
			}
			.class("breadcrumb-list")
			.style {
				display(.flex)
				alignItems(.center)
				gap(spacing4)
				listStyle(.none)
				margin(0)
				padding(0)
			}
		}
		.class(`class`.isEmpty ? "breadcrumb-view" : "breadcrumb-view \(`class`)")
		.ariaLabel("Breadcrumb")
		.style {
			breadcrumbViewCSS()
		}
		.render(indent: indent)
	}
}

#endif
