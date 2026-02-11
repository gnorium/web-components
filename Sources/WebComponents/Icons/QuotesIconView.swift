#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct QuotesIconView: HTMLProtocol {
	let width: Length
	let height: Length
	let `class`: String

	public init(
		width: Length = px(20),
		height: Length = px(20),
		class: String = ""
	) {
		self.width = width
		self.height = height
		self.class = `class`
	}

	public func render(indent: Int = 0) -> String {
		svg {
			path()
				.d(m(7, 6), l(1, -2), H(6), C(3.79, 4, 2, 6.79, 2, 9), v(7), h(7), V(9), H(5), c(0, -3, 2, -3, 2, -3), m(7, 3), c(0, -3, 2, -3, 2, -3), l(1, -2), h(-2), c(-2.21, 0, -4, 2.79, -4, 5), v(7), h(7), V(9), Z())
		}
		.class(`class`.isEmpty ? "quotes-icon-view" : "quotes-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
