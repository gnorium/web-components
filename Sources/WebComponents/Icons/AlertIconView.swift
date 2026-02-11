#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct AlertIconView: HTMLProtocol {
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
			.d(M(11.53, 2.3), A(1.85, 1.85, 0, false, false, 10, 1.21), A(1.85, 1.85, 0, false, false, 8.48, 2.3), L(0.36, 16.36), C(-0.48, 17.81, 0.21, 19, 1.88, 19), h(16.24), c(1.67, 0, 2.36, -1.19, 1.52, -2.64), Z(), M(11, 16), H(9), v(-2), h(2), Z(), m(0, -4), H(9), V(6), h(2), Z())
		}
		.class(`class`.isEmpty ? "alert-icon-view" : "alert-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
