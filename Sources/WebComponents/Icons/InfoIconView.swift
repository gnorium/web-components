#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct InfoIconView: HTMLProtocol {
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
			.d(M(4, 10), a(6, 6, 0, true, false, 12, 0), a(6, 6, 0, false, false, -12, 0), m(6, -8), a(8, 8, 0, true, true, 0, 16), a(8, 8, 0, false, true, 0, -16), m(1, 7), v(5), H(9), V(9), Z(), m(0, -1), V(6), H(9), v(2), Z())
		}
		.class(`class`.isEmpty ? "info-icon-view" : "info-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
