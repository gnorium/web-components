#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct VolumeUpIconView: HTML {
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
				.d(M(4, 6), v(8), l(5.2, 3.9), c(0.3, 0.3, 0.8, 0, 0.8, -0.5), V(2.6), c(0, -0.5, -0.5, -0.8, -0.8, -0.5), Z(), m(0, 8), H(1), a(1, 1, 0, false, true, -1, -1), V(7), a(1, 1, 0, false, true, 1, -1), h(3), m(12.4, 11.4), a(1, 1, 0, false, true, -0.7, -1.7), a(8, 8, 0, false, false, 0, -11.4), A(1, 1, 0, false, true, 17, 3), a(10, 10, 0, false, true, 0, 14.2), a(1, 1, 0, false, true, -0.7, 0.3), Z())

			path()
				.d(M(13.5, 14.5), a(1, 1, 0, false, true, -0.7, -0.3), a(1, 1, 0, false, true, 0, -1.4), a(4, 4, 0, false, false, 0, -5.6), a(1, 1, 0, false, true, 1.4, -1.4), a(6, 6, 0, false, true, 0, 8.4), a(1, 1, 0, false, true, -0.7, 0.3))
		}
		.class(`class`.isEmpty ? "volume-up-icon-view" : "volume-up-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
