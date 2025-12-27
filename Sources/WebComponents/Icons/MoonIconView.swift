#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct MoonIconView: HTML {
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
			.d(M(17.39, 15.14), A(7.33, 7.33, 0, false, true, 11.75, 1.6), c(0.23, -0.11, 0.56, -0.23, 0.79, -0.34), a(8.2, 8.2, 0, false, false, -5.41, 0.45), a(9, 9, 0, true, false, 7, 16.58), a(8.42, 8.42, 0, false, false, 4.29, -3.84), a(5.3, 5.3, 0, false, true, -1.03, 0.69))
		}
		.class(`class`.isEmpty ? "moon-icon-view" : "moon-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
