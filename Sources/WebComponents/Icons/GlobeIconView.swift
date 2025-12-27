#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct GlobeIconView: HTML {
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
			.d(M(12.2, 17.94), c(1.26, -2, 2, -4.45, 2.14, -7.06), h(3.86), a(8.26, 8.26, 0, false, true, -6, 7.06), M(1.8, 10.88), h(3.86), c(0.14, 2.6, 0.88, 5.06, 2.14, 7.06), a(8.26, 8.26, 0, false, true, -6, -7.06), m(6, -8.82), c(-1.26, 2, -2, 4.45, -2.14, 7.07), H(1.8), a(8.26, 8.26, 0, false, true, 6, -7.07), m(4.79, 8.82), A(12.5, 12.5, 0, false, true, 10, 18), a(12.5, 12.5, 0, false, true, -2.59, -7.13), Z(), M(7.4, 9.13), A(12.5, 12.5, 0, false, true, 10, 1.99), a(12.5, 12.5, 0, false, true, 2.59, 7.14), Z(), m(10.8, 0), h(-3.87), a(14.8, 14.8, 0, false, false, -2.14, -7.07), a(8.26, 8.26, 0, false, true, 6, 7.07), M(10, 0), a(10, 10, 0, true, false, 0, 20), a(10, 10, 0, false, false, 0, -20))
		}
		.class(`class`.isEmpty ? "globe-icon-view" : "globe-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
