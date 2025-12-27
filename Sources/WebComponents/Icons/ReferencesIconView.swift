#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ReferencesIconView: HTML {
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
				.d(M(0, 3), v(16), h(5), V(3), Z(), m(4, 12), H(1), v(-1), h(3), Z(), m(0, -3), H(1), v(-1), h(3), Z(), m(2, -9), v(16), h(5), V(3), Z(), m(4, 12), H(7), v(-1), h(3), Z(), m(0, -3), H(7), v(-1), h(3), Z(), m(1, -8.5), l(4.1, 15.4), l(4.8, -1.3), l(-4, -15.3), Z(), m(7, 10.6), l(-2.9, 0.8), l(-0.3, -1), l(2.9, -0.8), Z(), m(-0.8, -2.9), l(-2.9, 0.8), l(-0.2, -1), l(2.9, -0.8), Z())
		}
		.class(`class`.isEmpty ? "references-icon-view" : "references-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
