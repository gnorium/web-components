#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct LogInIconView: HTML {
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
				.d(M(1, 11), v(6), c(0, 1.1, 0.9, 2, 2, 2), h(14), c(1.1, 0, 2, -0.9, 2, -2), V(3), c(0, -1.1, -0.9, -2, -2, -2), H(3), c(-1.1, 0, -2, 0.9, -2, 2), v(6), h(8), V(5), l(4.75, 5), L(9, 15), v(-4), Z())
		}
		.class(`class`.isEmpty ? "log-in-icon-view" : "log-in-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
