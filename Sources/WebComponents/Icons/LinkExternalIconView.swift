#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct LinkExternalIconView: HTML {
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
				.d(M(19, 1), h(-8), l(3.286, 3.286), L(6, 12), l(1.371, 1.472), l(8.332, -7.77), l(0.007, 0.008), L(19, 9), Z(), M(2, 5), h(4), v(2), H(3), v(10), h(10), v(-4.004), h(2), V(18), a(1, 1, 0, false, true, -1, 1), H(2), a(1, 1, 0, false, true, -1, -1), V(6), a(1, 1, 0, false, true, 1, -1))
		}
		.class(`class`.isEmpty ? "link-external-icon-view" : "link-external-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
