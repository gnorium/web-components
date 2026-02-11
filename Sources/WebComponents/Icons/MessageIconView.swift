#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct MessageIconView: HTMLProtocol {
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
			.d(M(0, 8), v(8), a(2, 2, 0, false, false, 2, 2), h(16), a(2, 2, 0, false, false, 2, -2), V(8), l(-10, 4), Z())

			path()
			.d(M(2, 2), a(2, 2, 0, false, false, -2, 2), v(2), l(10, 4), l(10, -4), V(4), a(2, 2, 0, false, false, -2, -2), Z())
		}
		.class(`class`.isEmpty ? "message-icon-view" : "message-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
