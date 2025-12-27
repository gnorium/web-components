#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct MoveFirstIconView: HTML {
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
				.d(M(3, 1), h(2), v(18), H(3), Z(), m(13.5, 1.5), L(15, 1), l(-9, 9), l(9, 9), l(1.5, -1.5), L(9, 10), Z())
		}
		.class(`class`.isEmpty ? "move-first-icon-view" : "move-first-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
