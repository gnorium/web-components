#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct DeleteIconView: HTML {
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
			path()
				.d(M(20, 5), H(9), l(-7, 7), l(7, 7), h(11), a(2, 2, 0, false, false, 2, -2), V(7), a(2, 2, 0, false, false, -2, -2), Z(), M(18, 9), l(-6, 6), M(12, 9), l(6, 6))
		}
		.class(`class`.isEmpty ? "delete-icon-view" : "delete-icon-view \(`class`)")
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
