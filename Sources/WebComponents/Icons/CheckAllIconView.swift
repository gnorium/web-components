#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct CheckAllIconView: HTMLProtocol {
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
				.d(m(0.29, 12.71), l(1.42, -1.42), l(2.22, 2.22), l(8.3, -10.14), l(1.54, 1.26), l(-9.7, 11.86), Z(), M(12, 10), h(5), v(2), h(-5), Z(), m(-3, 4), h(5), v(2), H(9), Z(), m(6, -8), h(5), v(2), h(-5), Z())
		}
		.class(`class`.isEmpty ? "check-all-icon-view" : "check-all-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
