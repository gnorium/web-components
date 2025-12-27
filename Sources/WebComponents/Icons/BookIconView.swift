#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct BookIconView: HTML {
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
			.d(M(15, 2), a(7.65, 7.65, 0, false, false, -5, 2), a(7.65, 7.65, 0, false, false, -5, -2), H(1), v(15), h(4), a(7.65, 7.65, 0, false, true, 5, 2), a(7.65, 7.65, 0, false, true, 5, -2), h(4), V(2), Z(), m(2.5, 13.5), H(14), a(4.38, 4.38, 0, false, false, -3, 1), V(5), s(1, -1.5, 4, -1.5), h(2.5), Z())

			path()
				.d(M(9, 3.5), h(2), v(1), H(9), Z())
		}
		.class(`class`.isEmpty ? "book-icon-view" : "book-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
