#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ArticleIconView: HTML {
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
				.d(M(5, 1), a(2, 2, 0, false, false, -2, 2), v(14), a(2, 2, 0, false, false, 2, 2), h(10), a(2, 2, 0, false, false, 2, -2), V(3), a(2, 2, 0, false, false, -2, -2), Z(), m(0, 3), h(5), v(1), H(5), Z(), m(0, 2), h(5), v(1), H(5), Z(), m(0, 2), h(5), v(1), H(5), Z(), m(10, 7), H(5), v(-1), h(10), Z(), m(0, -2), H(5), v(-1), h(10), Z(), m(0, -2), H(5), v(-1), h(10), Z(), m(0, -2), h(-4), V(4), h(4), Z())
		}
		.class(`class`.isEmpty ? "article-icon-view" : "article-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
