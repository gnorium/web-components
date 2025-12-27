#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ClearIconView: HTML {
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
				.d(M(10, 0), a(10, 10, 0, true, false, 10, 10), A(10, 10, 0, false, false, 10, 0), m(5.66, 14.24), l(-1.41, 1.41), L(10, 11.41), l(-4.24, 4.25), l(-1.42, -1.42), L(8.59, 10), L(4.34, 5.76), l(1.42, -1.42), L(10, 8.59), l(4.24, -4.24), l(1.41, 1.41), L(11.41, 10), Z())
		}
		.class(`class`.isEmpty ? "clear-icon-view" : "clear-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
