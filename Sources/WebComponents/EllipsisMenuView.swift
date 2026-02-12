#if !os(WASI)

import CSSBuilder
import DesignTokens
import HTMLBuilder
import WebTypes

/// Full-screen overlay menu triggered by EllipsisMenuButtonView.
/// Renders a blurred backdrop + slide-down container below the navbar.
/// Pass app-specific content (sections, toggles, links) via the content closure.
public struct EllipsisMenuView: HTMLProtocol {
	let `class`: String
	let navbarHeight: Int
	let content: [HTMLProtocol]

	public init(
		class: String = "",
		navbarHeight: Int = 96,
		@HTMLBuilder content: () -> [HTMLProtocol]
	) {
		self.class = `class`
		self.navbarHeight = navbarHeight
		self.content = content()
	}

	public func render(indent: Int = 0) -> String {
		div {
			// Backdrop with blur effect
			div {}
			.class("ellipsis-menu-backdrop")
			.data("ellipsis-menu-backdrop", "true")
			.style {
				ellipsisMenuBackdropCSS()
			}

			// Menu container — slides down from navbar
			div {
				ContainerView(size: .xLarge) {
					div {
						content
					}
					.style {
						display(.flex)
						flexDirection(.column)
						gap(spacing8)
					}
				}
			}
			.class("ellipsis-menu-container")
			.data("ellipsis-menu-container", "true")
			.style {
				ellipsisMenuContainerCSS()
			}
		}
		.id("navbar-ellipsis-menu")
		.class(`class`.isEmpty ? "ellipsis-menu-view" : "ellipsis-menu-view \(`class`)")
		.data("ellipsis-menu", "true")
		.ariaHidden(true)
		.style {
			ellipsisMenuViewCSS()
		}
		.render(indent: indent)
	}

	// MARK: - CSS

	@CSSBuilder
	private func ellipsisMenuViewCSS() -> [CSSProtocol] {
		display(.none)
		position(.fixed)
		top(px(navbarHeight))
		insetInlineStart(0)
		width(perc(100))
		zIndex(zIndexOverlay)
		pointerEvents(.none)
	}

	@CSSBuilder
	private func ellipsisMenuBackdropCSS() -> [CSSProtocol] {
		position(.fixed)
		top(px(navbarHeight))
		insetInlineStart(0)
		width(perc(100))
		height(calc(vh(100) - px(navbarHeight)))
		backgroundColor(rgba(0, 0, 0, 0.4))
		backdropFilter(blur(rem(1)))
		webkitBackdropFilter(blur(rem(1)))
		opacity(0)
		transition(.opacity, transitionDurationMedium, transitionTimingFunctionSystem)
		zIndex(-1)
	}

	@CSSBuilder
	private func ellipsisMenuContainerCSS() -> [CSSProtocol] {
		position(.relative)
		width(perc(100))
		backgroundColor(backgroundColorBase)
		paddingBlockStart(spacing16)
		paddingBlockEnd(spacing16)
		borderBlockEnd(borderWidthBase, .solid, borderColorBase)

		maxHeight(px(0))
		overflow(.hidden)
		transform(translateY(px(-125)))
		transition(
			(.maxHeight, transitionDurationMedium, transitionTimingFunctionSystem),
			(.opacity, transitionDurationMedium, transitionTimingFunctionSystem),
			(.transform, transitionDurationMedium, transitionTimingFunctionSystem)
		)
		opacity(0)

		media(minWidth(minWidthBreakpointTablet)) {
			paddingBlockStart(spacing20)
			paddingBlockEnd(spacing20)
		}
	}

	// MARK: - Public Section Helpers

	@CSSBuilder
	public static func sectionCSS() -> [CSSProtocol] {
		display(.flex)
		flexDirection(.column)
		gap(spacing8)
	}

	@CSSBuilder
	public static func sectionHeaderCSS() -> [CSSProtocol] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeXSmall12)
		fontWeight(fontWeightSemiBold)
		color(colorSubtle)
		letterSpacing(px(0.5))
	}

	@CSSBuilder
	public static func dividerCSS() -> [CSSProtocol] {
		height(px(1))
		backgroundColor(borderColorSubtle)
	}
}

#endif
