#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct HelpIconView: HTMLProtocol {
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
				.d(M(10.06, 1), C(13, 1, 15, 2.89, 15, 5.53), a(4.59, 4.59, 0, false, true, -2.29, 4.08), c(-1.42, 0.92, -1.82, 1.53, -1.82, 2.71), V(13), H(8.38), v(-0.81), a(3.84, 3.84, 0, false, true, 2, -3.84), c(1.34, -0.9, 1.79, -1.53, 1.79, -2.71), a(2.1, 2.1, 0, false, false, -2.08, -2.14), h(-0.17), a(2.3, 2.3, 0, false, false, -2.38, 2.22), v(0.17), H(5), A(4.71, 4.71, 0, false, true, 9.51, 1), a(5, 5, 0, false, true, 0.55, 0))

			circle()
				.cx(10)
				.cy(17)
				.r(2)
		}
		.class(`class`.isEmpty ? "help-icon-view" : "help-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
