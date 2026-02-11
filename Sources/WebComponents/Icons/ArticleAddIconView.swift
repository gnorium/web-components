#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ArticleAddIconView: HTMLProtocol {
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
				.d(M(5, 1), c(-1.1, 0, -2, 0.9, -2, 2), v(14), c(0, 1.1, 0.9, 2, 2, 2), h(10), c(1.1, 0, 2, -0.9, 2, -2), V(3), c(0, -1.1, -0.9, -2, -2, -2), Z(), m(10, 10), h(-4), v(4), H(9), v(-4), H(5), V(9), h(4), V(5), h(2), v(4), h(4), Z())
		}
		.class(`class`.isEmpty ? "article-add-icon-view" : "article-add-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
