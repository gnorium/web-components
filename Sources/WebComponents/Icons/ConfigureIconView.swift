#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ConfigureIconView: HTML {
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
				.fillRule(.evenodd)
				.d(M(3, 4.17), V(2), h(2), v(2.17), a(3.001, 3.001, 0, false, true, 0, 5.66), V(18), H(3), V(9.83), a(3.001, 3.001, 0, false, true, 0, -5.66), M(4, 6), a(1, 1, 0, true, true, 0, 2), a(1, 1, 0, false, true, 0, -2), m(11, 12), v(-6.17), a(3.001, 3.001, 0, false, true, 0, -5.66), V(2), h(2), v(4.17), a(3.001, 3.001, 0, false, true, 0, 5.66), V(18), Z(), m(2, -9), a(1, 1, 0, true, false, -2, 0), a(1, 1, 0, false, false, 2, 0))

			path()
				.fillRule(.evenodd)
				.d(M(11, 11.17), a(3.001, 3.001, 0, false, true, 0, 5.66), V(18), H(9), v(-1.17), a(3.001, 3.001, 0, false, true, 0, -5.66), V(2), h(2), Z(), M(10, 13), a(1, 1, 0, true, true, 0, 2), a(1, 1, 0, false, true, 0, -2))
		}
		.class(`class`.isEmpty ? "configure-icon-view" : "configure-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
