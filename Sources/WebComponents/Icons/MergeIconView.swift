#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct MergeIconView: HTML {
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
				.d(M(1, 4.4), L(2.4, 3), l(4.85, 4.83), A(3.98, 3.98, 0, false, false, 10.07, 9), h(5.1), L(13.6, 7.4), L(15, 6), l(4, 4), l(-4, 4), l(-1.4, -1.4), l(1.58, -1.6), h(-5.1), a(3.95, 3.95, 0, false, false, -2.83, 1.18), L(2.4, 17), L(1, 15.6), L(6.6, 10), Z())
		}
		.class(`class`.isEmpty ? "merge-icon-view" : "merge-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
