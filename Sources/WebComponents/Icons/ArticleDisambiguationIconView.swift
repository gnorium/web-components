#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ArticleDisambiguationIconView: HTMLProtocol {
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
				.d(M(15, 1), H(5), c(-1.1, 0, -2, 0.9, -2, 2), v(6), h(4.6), l(3.7, -3.7), L(10, 4), h(4), v(4), l(-1.3, -1.3), L(9.4, 10), l(3.3, 3.3), L(14, 12), v(4), h(-4), l(1.3, -1.3), L(7.6, 11), H(3), v(6), c(0, 1.1, 0.9, 2, 2, 2), h(10), c(1.1, 0, 2, -0.9, 2, -2), V(3), c(0, -1.1, -0.9, -2, -2, -2))
		}
		.class(`class`.isEmpty ? "article-disambiguation-icon-view" : "article-disambiguation-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
