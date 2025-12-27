#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ListBulletIconView: HTML {
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
				.d(M(7, 15), h(12), v(2), H(7), Z(), m(0, -6), h(12), v(2), H(7), Z(), m(0, -6), h(12), v(2), H(7), Z())

			circle()
				.cx(3)
				.cy(4)
				.r(2)

			circle()
				.cx(3)
				.cy(10)
				.r(2)

			circle()
				.cx(3)
				.cy(16)
				.r(2)
		}
		.class(`class`.isEmpty ? "list-bullet-icon-view" : "list-bullet-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
