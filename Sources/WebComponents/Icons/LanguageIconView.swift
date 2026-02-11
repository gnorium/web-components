#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct LanguageIconView: HTMLProtocol {
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
			.d(M(20, 18), h(-1.44), a(0.6, 0.6, 0, false, true, -0.4, -0.12), a(0.8, 0.8, 0, false, true, -0.23, -0.31), L(17, 15), h(-5), l(-1, 2.54), a(0.8, 0.8, 0, false, true, -0.22, 0.3), a(0.6, 0.6, 0, false, true, -0.4, 0.14), H(9), l(4.55, -11.47), h(1.89), Z(), m(-3.53, -4.31), L(14.89, 9.5), a(12, 12, 0, false, true, -0.39, -1.24), q(-0.09, 0.37, -0.19, 0.69), l(-0.19, 0.56), l(-1.58, 4.19), Z(), m(-6.3, -1.58), a(13.4, 13.4, 0, false, true, -2.91, -1.41), a(11.46, 11.46, 0, false, false, 2.81, -5.37), H(12), V(4), H(7.31), a(4, 4, 0, false, false, -0.2, -0.56), C(6.87, 2.79, 6.6, 2, 6.6, 2), l(-1.47, 0.5), s(0.4, 0.89, 0.6, 1.5), H(0), v(1.33), h(2.15), A(11.23, 11.23, 0, false, false, 5, 10.7), a(17.2, 17.2, 0, false, true, -5, 2.1), q(0.56, 0.82, 0.87, 1.38), a(23.3, 23.3, 0, false, false, 5.22, -2.51), a(15.6, 15.6, 0, false, false, 3.56, 1.77), Z(), M(3.63, 5.33), h(4.91), a(8.1, 8.1, 0, false, true, -2.45, 4.45), a(9.1, 9.1, 0, false, true, -2.46, -4.45))
		}
		.class(`class`.isEmpty ? "language-icon-view" : "language-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
