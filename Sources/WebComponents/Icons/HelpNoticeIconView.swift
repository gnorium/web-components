#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct HelpNoticeIconView: HTML {
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
			.d(M(10, 0), a(10, 10, 0, true, false, 10, 10), A(10, 10, 0, false, false, 10, 0), m(1, 16), H(9), v(-2), h(2), Z(), m(2.71, -7.6), a(2.6, 2.6, 0, false, true, -0.33, 0.74), a(3.2, 3.2, 0, false, true, -0.48, 0.55), l(-0.54, 0.48), c(-0.21, 0.18, -0.41, 0.35, -0.58, 0.52), a(2.5, 2.5, 0, false, false, -0.47, 0.56), A(2.3, 2.3, 0, false, false, 11, 12), a(3.8, 3.8, 0, false, false, -0.11, 1), H(9.08), a(9, 9, 0, false, true, 0.07, -1.25), a(3.3, 3.3, 0, false, true, 0.25, -0.9), a(2.8, 2.8, 0, false, true, 0.41, -0.67), a(4, 4, 0, false, true, 0.58, -0.58), c(0.17, -0.16, 0.34, -0.3, 0.51, -0.44), a(3, 3, 0, false, false, 0.43, -0.44), a(1.8, 1.8, 0, false, false, 0.3, -0.55), a(2, 2, 0, false, false, 0.11, -0.72), a(2.1, 2.1, 0, false, false, -0.17, -0.86), a(1.7, 1.7, 0, false, false, -1, -0.9), a(1.7, 1.7, 0, false, false, -0.5, -0.1), a(1.77, 1.77, 0, false, false, -1.53, 0.68), a(3, 3, 0, false, false, -0.5, 1.82), H(6.16), a(4.7, 4.7, 0, false, true, 0.28, -1.68), a(3.6, 3.6, 0, false, true, 0.8, -1.29), a(3.9, 3.9, 0, false, true, 1.28, -0.83), A(4.6, 4.6, 0, false, true, 10.18, 4), a(4.4, 4.4, 0, false, true, 1.44, 0.23), a(3.5, 3.5, 0, false, true, 1.15, 0.65), a(3.1, 3.1, 0, false, true, 0.78, 1.06), a(3.5, 3.5, 0, false, true, 0.29, 1.45), a(3.4, 3.4, 0, false, true, -0.13, 1.01))
		}
		.class(`class`.isEmpty ? "help-notice-icon-view" : "help-notice-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
