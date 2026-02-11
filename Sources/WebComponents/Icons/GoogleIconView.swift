#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct GoogleIconView: HTMLProtocol {
	let `class`: String
	let width: Length
	let height: Length

	public init(
		class: String = "",
		width: Length = px(20),
		height: Length = px(20)
	) {
		self.class = `class`
		self.width = width
		self.height = height
	}

	public func render(indent: Int = 0) -> String {
		svg {
			path()
				.d(M(22.56, 12.25), c(0, -0.78, -0.07, -1.53, -0.2, -2.25), H(12), v(4.26), h(5.92), c(-0.26, 1.37, -1.04, 2.53, -2.21, 3.31), v(2.77), h(3.57), c(2.08, -1.92, 3.28, -4.74, 3.28, -8.09), Z())
				.fill(SVGPaint(hex(0x4285F4)))
			path()
				.d(M(12, 23), c(2.97, 0, 5.46, -0.98, 7.28, -2.66), l(-3.57, -2.77), c(-0.98, 0.66, -2.23, 1.06, -3.71, 1.06), c(-2.86, 0, -5.29, -1.93, -6.16, -4.53), H(2.18), v(2.84), C(3.99, 20.53, 7.7, 23, 12, 23), Z())
				.fill(SVGPaint(hex(0x34A853)))
			path()
				.d(M(5.84, 14.09), c(-0.22, -0.66, -0.35, -1.36, -0.35, -2.09), s(0.13, -1.43, 0.35, -2.09), V(7.07), H(2.18), C(1.43, 8.55, 1, 10.22, 1, 12), s(0.43, 3.45, 1.18, 4.93), l(2.85, -2.22), l(0.81, -0.62), Z())
				.fill(SVGPaint(hex(0xFBBC05)))
			path()
				.d(M(12, 5.38), c(1.62, 0, 3.06, 0.56, 4.21, 1.64), l(3.15, -3.15), C(17.45, 2.09, 14.97, 1, 12, 1), C(7.7, 1, 3.99, 3.47, 2.18, 7.07), l(3.66, 2.84), c(0.87, -2.6, 3.3, -4.53, 6.16, -4.53), Z())
				.fill(SVGPaint(hex(0xEA4335)))
		}
		.class(`class`.isEmpty ? "google-icon-view" : "google-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 24, 24)
		.xmlns("http://www.w3.org/2000/svg")
		.xmlnsXlink("http://www.w3.org/1999/xlink")
		.render(indent: indent)
	}
}

#endif
