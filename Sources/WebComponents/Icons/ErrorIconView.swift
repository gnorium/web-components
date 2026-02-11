#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ErrorIconView: HTMLProtocol {
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
			.d(M(13.728, 1), H(6.272), L(1, 6.272), v(7.456), L(6.272, 19), h(7.456), L(19, 13.728), V(6.272), Z(), M(11, 15), H(9), v(-2), h(2), Z(), m(0, -4), H(9), V(5), h(2), Z())
		}
		.class(`class`.isEmpty ? "error-icon-view" : "error-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
