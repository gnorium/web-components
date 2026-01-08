#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct CloseButtonView: HTML {
	let ariaLabel: String
	let `class`: String

	public init(
		ariaLabel: String = "Close",
		class customClass: String = ""
	) {
		self.ariaLabel = ariaLabel
		self.class = customClass
	}

	public func render(indent: Int = 0) -> String {
		button {
			CloseIconView(width: sizeIconMedium, height: sizeIconMedium)
		}
		.type(.button)
		.ariaLabel(ariaLabel)
		.class("close-button \(self.class)".trimmingCharacters(in: .whitespaces))
		.style {
			closeButtonCSS()
		}
		.render(indent: indent)
	}

	@CSSBuilder
	private func closeButtonCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		minWidth(sizeIconMedium)
		width(sizeIconMedium)
		height(sizeIconMedium)
		padding(0)
		border(.none)
		backgroundColor(.transparent)
		color(colorSubtle)
		fontSize(sizeIconMedium)
		cursor(cursorBaseHover)
		borderRadius(borderRadiusBase)
		transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
		flexShrink(0)

		pseudoClass(.hover) {
			backgroundColor(backgroundColorInteractiveSubtleHover)
		}

		pseudoClass(.active) {
			backgroundColor(backgroundColorInteractiveSubtleActive)
		}

		pseudoClass(.focus) {
			outline(borderWidthThick, .solid, borderColorProgressive)
			outlineOffset(px(1))
		}
	}
}

#endif
