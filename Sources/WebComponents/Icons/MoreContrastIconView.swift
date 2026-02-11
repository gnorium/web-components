#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct MoreContrastIconView: HTMLProtocol {
	let width: Length
	let height: Length
	let `class`: String

	public init(
		width: Length = px(16),
		height: Length = px(16),
		class: String = ""
	) {
		self.width = width
		self.height = height
		self.class = `class`
	}

	public func render(indent: Int = 0) -> String {
		svg {
			// Outer circle
			circle()
				.cx(12)
				.cy(12)
				.r(10)
				.fill(.none)
				.stroke(.currentColor)
				.strokeWidth(2)

			// Inner semicircle (filled - more contrast)
			path()
				.d(M(12, 18), a(6, 6, 0, false, false, 0, -12), v(12), Z())
				.fill(.currentColor)
				.stroke(.currentColor)
				.strokeWidth(2)
				.strokeLinecap(.round)
				.strokeLinejoin(.round)
		}
		.class(`class`.isEmpty ? "more-contrast-icon-view" : "more-contrast-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 24, 24)
		.xmlns("http://www.w3.org/2000/svg")
		.ariaHidden(true)
		.render(indent: indent)
	}
}

#endif
