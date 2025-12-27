#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct NewWindowIconView: HTML {
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
				.d(M(17, 17), H(3), V(3), h(5), V(1), H(3), a(2, 2, 0, false, false, -2, 2), v(14), a(2, 2, 0, false, false, 2, 2), h(14), a(2, 2, 0, false, false, 2, -2), v(-5), h(-2), Z())

			path()
				.d(m(11, 1), l(3.29, 3.29), l(-5.73, 5.73), l(1.42, 1.42), l(5.73, -5.73), L(19, 9), V(1), Z())
		}
		.class(`class`.isEmpty ? "new-window-icon-view" : "new-window-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
