#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct ViewDetailsIconView: HTML {
	let `class`: String
	let width: Length
	let height: Length

	public init(
		class: String = "",
		width: Length = px(18),
		height: Length = px(18)
	) {
		self.class = `class`
		self.width = width
		self.height = height
	}

	public func render(indent: Int = 0) -> String {
		svg {
			rect()
				.width(px(7))
				.height(px(7))
				.x(px(3))
				.y(px(3))
				.rx(px(1))

			rect()
				.width(px(7))
				.height(px(7))
				.x(px(3))
				.y(px(14))
				.rx(px(1))

			path()
				.d(M(14, 4), h(7), M(14, 9), h(7), M(14, 15), h(7), M(14, 20), h(7))
		}
		.class(`class`.isEmpty ? "view-details-icon-view" : "view-details-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 24, 24)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.none)
		.stroke(.currentColor)
		.strokeLinecap(.round)
		.strokeLinejoin(.round)
		.strokeWidth(px(2))
		.render(indent: indent)
	}
}

#endif
