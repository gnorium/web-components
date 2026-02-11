#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct CopyIconView: HTMLProtocol {
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
				.d(M(3, 3), h(8), v(2), h(2), V(3), c(0, -1.1, -0.895, -2, -2, -2), H(3), c(-1.1, 0, -2, 0.895, -2, 2), v(8), c(0, 1.1, 0.895, 2, 2, 2), h(2), v(-2), H(3), Z())
			path()
				.d(M(9, 9), h(8), v(8), H(9), Z(), m(0, -2), c(-1.1, 0, -2, 0.895, -2, 2), v(8), c(0, 1.1, 0.895, 2, 2, 2), h(8), c(1.1, 0, 2, -0.895, 2, -2), V(9), c(0, -1.1, -0.895, -2, -2, -2), Z())
		}
		.class(`class`.isEmpty ? "copy-icon-view" : "copy-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
