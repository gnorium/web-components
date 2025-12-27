#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct HeartIconView: HTML {
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
			.d(M(14.75, 1), A(5.24, 5.24, 0, false, false, 10, 4), A(5.24, 5.24, 0, false, false, 0, 6.25), C(0, 11.75, 10, 19, 10, 19), s(10, -7.25, 10, -12.75), A(5.25, 5.25, 0, false, false, 14.75, 1))
		}
		.class(`class`.isEmpty ? "heart-icon-view" : "heart-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
